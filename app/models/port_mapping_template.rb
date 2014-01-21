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

class PortMappingTemplate < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance_type
  belongs_to :dev_mode_property_set

  validates_presence_of :appliance_type, if: 'dev_mode_property_set == nil'
  validates_presence_of :dev_mode_property_set, if: 'appliance_type == nil'

  validates_absence_of :appliance_type, if: 'dev_mode_property_set != nil'
  validates_absence_of :dev_mode_property_set, if: 'appliance_type != nil'

  before_validation :check_only_one_belonging
  before_destroy :cant_change_used_appliance_type
  before_create :cant_change_used_appliance_type
  before_update :cant_change_used_appliance_type

  validates_presence_of :service_name, :target_port, :application_protocol, :transport_protocol

  enumerize :application_protocol, in: [:http, :https, :http_https, :none]
  enumerize :transport_protocol, in: [:tcp, :udp]

  validates_inclusion_of :transport_protocol, in: %w(tcp udp)
  validates_inclusion_of :application_protocol, in: %w(http https http_https none), if: 'transport_protocol == "tcp"'
  validates_inclusion_of :application_protocol, in: %w(none), if: 'transport_protocol == "udp"'

  validates_uniqueness_of :service_name, scope: [:appliance_type, :dev_mode_property_set]
  validates_uniqueness_of :target_port, scope: [:appliance_type, :dev_mode_property_set]
  validates :target_port, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :http_mappings, dependent: :destroy
  has_many :port_mappings, dependent: :destroy
  has_many :port_mapping_properties, dependent: :destroy, autosave: true
  has_many :endpoints, dependent: :destroy, autosave: true

  before_validation :strip_service_name

  after_save :generate_proxy_conf
  after_create :add_port_mappings_to_associated_vms
  after_update :update_port_mappings, if: :target_port_changed?
  after_update :remove_dnat_port_mappings if :type_changed_into_http?
  after_update :add_port_mappings_to_associated_vms if :type_changed_into_dnat?
  after_destroy :generate_proxy_conf

  scope :def_order, -> { order(:service_name) }

  def http?
    application_protocol.http? || application_protocol.http_https?
  end

  def https?
    application_protocol.https? || application_protocol.http_https?
  end

  def generate_proxy_conf
    if regenerate_proxy_conf?
      affected_sites = dev_mode_property_set.blank? ? ComputeSite.with_appliance_type(appliance_type) : ComputeSite.with_dev_property_set(dev_mode_property_set)

      affected_sites.each do |site|
        ProxyConfWorker.regeneration_required(site)
      end
    end
  end

  private

  def check_only_one_belonging
    unless appliance_type.blank? or dev_mode_property_set.blank?
      errors.add :base, 'Port Mapping template cannot belong to both Appliance Type and Dev Mode Property Set'
      false
    end
  end

  def cant_change_used_appliance_type
    if appliance_type and appliance_type.has_dependencies?
      errors.add :base, 'Appliance Type cannot be modified when used in Appliance or Virtual Machine Templates'
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
      DnatWrangler.instance.remove(pm.virtual_machine.ip, target_port_was)
      added_mapping_attrs = DnatWrangler.instance.add_dnat_for_vm(pm.virtual_machine, [self])
      pm.update_attributes(added_mapping_attrs)
    }
  end

  def strip_service_name
    self.service_name.strip! if self.service_name
  end

  def type_changed_into_http?
    application_protocol.to_sym != :none && application_protocol_was.to_sym == :none
  end

  def type_changed_into_dnat?
    application_protocol.to_sym == :none && application_protocol_was.to_sym != :none
  end

  def regenerate_proxy_conf?
    http? || https? || type_changed_into_dnat?
  end

  def remove_dnat_port_mappings
    port_mappings.destroy_all
  end
end
