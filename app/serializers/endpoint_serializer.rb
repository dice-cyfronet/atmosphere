class EndpointSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :description, :descriptor, :endpoint_type, :invocation_path

  has_one :port_mapping_template
end
