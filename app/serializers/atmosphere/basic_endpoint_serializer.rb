#
# Endpoint serializer returning only basic information.
#
module Atmosphere
  class BasicEndpointSerializer < ActiveModel::Serializer
    attributes :id, :name, :description, :endpoint_type, :url

    def url
      descriptor_api_v1_endpoint_url(object.id)
    end
  end
end
