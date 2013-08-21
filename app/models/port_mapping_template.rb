class PortMappingTemplate < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance_type

  validates_presence_of :service_name, :target_port, :application_protocol, :transport_protocol

  enumerize :application_protocol, in: [:http, :https, :http_https, :none]
  enumerize :transport_protocol, in: [:tcp, :udp]

  validates_inclusion_of :transport_protocol, in: %w(tcp udp)
  validates_inclusion_of :application_protocol, in: %w(http https http_https), if: 'transport_protocol == "tcp"'
  validates_inclusion_of :application_protocol, in: %w(none), if: 'transport_protocol == "udp"'

  has_many :http_mappings
end
