#
# Port mapping template serializer.
#
module Atmosphere
  class PortMappingTemplateSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :transport_protocol, :application_protocol,
               :service_name, :target_port

    has_one :appliance_type
    has_one :dev_mode_property_set
  end
end
