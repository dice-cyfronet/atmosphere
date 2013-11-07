class HttpMappingSerializer < ActiveModel::Serializer
  embed :ids
  attributes :id, :application_protocol, :url
  has_one :appliance, :port_mapping_template
end
