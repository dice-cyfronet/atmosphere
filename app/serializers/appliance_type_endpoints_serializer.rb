class ApplianceTypeEndpointsSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
  has_many :endpoints, serializer: BasicEndpointSerializer

  def endpoints
    object.port_mapping_templates.collect do |pmt|
      pmt.endpoints
    end.flatten
  end
end
