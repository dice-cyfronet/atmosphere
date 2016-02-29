#
# Http mapping serializer with filtering capability.
#
module Atmosphere
  class HttpMappingSerializer < ActiveModel::Serializer
    embed :ids
    attributes :id, :application_protocol,
      :url, :monitoring_status, :custom_name, :custom_url
    has_one :appliance, :port_mapping_template
  end
end
