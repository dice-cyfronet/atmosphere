#
# Port mapping property serializer.
#
module Atmosphere
  class PortMappingPropertySerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :key, :value

    has_one :port_mapping_template
    has_one :tenant
  end
end
