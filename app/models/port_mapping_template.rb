class PortMappingTemplate < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance_type

  validates_presence_of :service_name, :target_port, :application_protocol, :transport_protocol

  enumerize :application_protocol, in: [:http, :https, :http_https, :none]
  enumerize :transport_protocol, in: [:tcp, :udp]

end
