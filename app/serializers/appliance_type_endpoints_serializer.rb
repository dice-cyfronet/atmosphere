class ApplianceTypeEndpointsSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
  has_many :endpoints, serializer: BasicEndpointSerializer

  def endpoints
    types = options[:endpoint_types]
    if types
      object.port_mapping_templates.collect do |pmt|
        pmt.endpoints.where(endpoint_type: types)
      end.flatten
    else
      object.port_mapping_templates.collect do |pmt|
        pmt.endpoints
      end.flatten
    end
  end
end
