class EndpointSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :description, :descriptor, :endpoint_type

  has_one :port_mapping_template
end
