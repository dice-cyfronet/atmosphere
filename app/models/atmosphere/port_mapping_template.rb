# == Schema Information
#
# Table name: port_mapping_templates
#
#  id                       :integer          not null, primary key
#  transport_protocol       :string(255)      default("tcp"), not null
#  application_protocol     :string(255)      default("http_https"), not null
#  service_name             :string(255)      not null
#  target_port              :integer          not null
#  appliance_type_id        :integer
#  dev_mode_property_set_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#
module Atmosphere
  class PortMappingTemplate < ActiveRecord::Base
    extend Enumerize
    include Slugable

    belongs_to :appliance_type,
      class_name: 'Atmosphere::ApplianceType'

    belongs_to :dev_mode_property_set,
      class_name: 'Atmosphere::DevModePropertySet'

    has_many :http_mappings,
      dependent: :destroy,
      class_name: 'Atmosphere::HttpMapping'

    has_many :port_mappings,
      dependent: :destroy,
      class_name: 'Atmosphere::PortMapping'

    has_many :port_mapping_properties,
      dependent: :destroy,
      autosave: true,
      class_name: 'Atmosphere::PortMappingProperty'

    has_many :endpoints,
      dependent: :destroy,
      autosave: true,
      class_name: 'Atmosphere::Endpoint'

    validates :appliance_type,
              presence: true,
              if: 'dev_mode_property_set == nil'

    validates :appliance_type,
              absence: true,
              if: 'dev_mode_property_set != nil'

    validates :dev_mode_property_set,
              presence: true,
              if: 'appliance_type == nil'

    validates :dev_mode_property_set,
              absence: true,
              if: 'appliance_type != nil'

    validates :transport_protocol,
              presence: true,
              inclusion: { in: %w(tcp udp) }

    validates :application_protocol,
              presence: true,
              inclusion: { in: %w(http https http_https none) },
              if: 'transport_protocol == "tcp"'

    validates :application_protocol,
              presence: true,
              inclusion: { in: %w(none) },
              if: 'transport_protocol == "udp"'

    validates :service_name,
              presence: true,
              uniqueness: { scope: [:appliance_type, :dev_mode_property_set] }

    validates :target_port,
              presence: true,
              uniqueness: { scope: [:appliance_type, :dev_mode_property_set] },
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
              }

    enumerize :application_protocol, in: [:http, :https, :http_https, :none]
    enumerize :transport_protocol, in: [:tcp, :udp]

    before_validation :check_only_one_belonging
    before_validation :slug_service_name

    after_create :add_port_mappings_to_associated_vms
    after_update :update_port_mappings, if: :target_port_changed?
    after_update :remove_dnat_port_mappings, if: :type_changed_into_http?
    after_update :add_port_mappings_to_associated_vms, if: :type_changed_into_dnat?

    scope :def_order, -> { order(:service_name) }

    def http?
      application_protocol.http? || application_protocol.http_https?
    end

    def https?
      application_protocol.https? || application_protocol.http_https?
    end

    def properties
      port_mapping_properties.collect { |pmp| pmp.to_s }
    end

    private

    def check_only_one_belonging
      unless appliance_type.blank? or dev_mode_property_set.blank?
        errors.add :base, 'Port Mapping template cannot belong to both Appliance Type and Dev Mode Property Set'
        false
      end
    end

    def add_port_mappings_to_associated_vms
      if appliance_type
        appliance_type.appliances.each {|appl| appl.virtual_machines.each {|vm| vm.add_dnat} }
      elsif dev_mode_property_set
        dev_mode_property_set.appliance.virtual_machines.each {|vm| vm.add_dnat}
      end
    end

    def update_port_mappings
      port_mappings.each {|pm|
        # TODO handle Wrangler errors
        dnat_client = pm.virtual_machine.tenant.dnat_client
        dnat_client.remove(pm.virtual_machine.ip, target_port_was)
        added_mapping_attrs = dnat_client.add_dnat_for_vm(pm.virtual_machine, [self])
        pm.update_attributes(added_mapping_attrs.first)
      }
    end

    def slug_service_name
      self.service_name = to_slug(self.service_name) if self.service_name
    end

    def type_changed_into_http?
      application_protocol.to_sym != :none && application_protocol_was.to_sym == :none
    end

    def type_changed_into_dnat?
      application_protocol.to_sym == :none && application_protocol_was.to_sym != :none
    end

    def remove_dnat_port_mappings
      port_mappings.destroy_all
    end
  end
end
