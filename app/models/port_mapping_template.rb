# == Schema Information
#
# Table name: port_mapping_templates
#
#  id                   :integer          not null, primary key
#  transport_protocol   :string(255)      default("tcp"), not null
#  application_protocol :string(255)      default("http_https"), not null
#  service_name         :string(255)      not null
#  target_port          :integer          not null
#  appliance_type_id    :integer          not null
#  created_at           :datetime
#  updated_at           :datetime
#

class PortMappingTemplate < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance_type

  validates_presence_of :service_name, :target_port, :application_protocol, :transport_protocol

  enumerize :application_protocol, in: [:http, :https, :http_https, :none]
  enumerize :transport_protocol, in: [:tcp, :udp]

  validates_inclusion_of :transport_protocol, in: %w(tcp udp)
  validates_inclusion_of :application_protocol, in: %w(http https http_https), if: 'transport_protocol == "tcp"'
  validates_inclusion_of :application_protocol, in: %w(none), if: 'transport_protocol == "udp"'

  validates :target_port, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :http_mappings
  has_many :port_mappings
  has_many :port_mapping_properties, dependent: :destroy
  has_many :endpoints, dependent: :destroy
end
