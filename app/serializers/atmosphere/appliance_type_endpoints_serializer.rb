#
# Appliance type endpoints serializer.
# It is capable of returning appliance type endpoints
# of given type.
#
module Atmosphere
  class ApplianceTypeEndpointsSerializer < ActiveModel::Serializer
    attributes :id, :name, :description
    has_many :endpoints, serializer: BasicEndpointSerializer

    def endpoints
      types = options[:endpoint_types]
      if types
        object.port_mapping_templates.map do |pmt|
          pmt.endpoints.where(endpoint_type: types)
        end.flatten
      else
        object.port_mapping_templates.map do |pmt|
          pmt.endpoints
        end.flatten
      end
    end
  end
end