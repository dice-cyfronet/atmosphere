class HttpMappingSerializer < ActiveModel::Serializer
  embed :ids
  attributes :id, :application_protocol, :url, :appliance, :port_mapping_template
end
