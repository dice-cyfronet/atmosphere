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

  validates_presence_of :service_name, :target_port, :application_protocol, :transport_protocol

  enumerize :application_protocol, in: [:http, :https, :http_https, :none]
  enumerize :transport_protocol, in: [:tcp, :udp]

  validates_inclusion_of :transport_protocol, in: %w(tcp udp)
  validates_inclusion_of :application_protocol, in: %w(http https http_https), if: 'transport_protocol == "tcp"'
  validates_inclusion_of :application_protocol, in: %w(none), if: 'transport_protocol == "udp"'

  validates_uniqueness_of :service_name, scope: :appliance_type
  validates_uniqueness_of :target_port, scope: :appliance_type
  validates :target_port, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :http_mappings, dependent: :destroy
  has_many :port_mappings, dependent: :destroy
  has_many :port_mapping_properties, dependent: :destroy
  has_many :endpoints, dependent: :destroy


  scope :def_order, -> { order(:service_name) }

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
end
