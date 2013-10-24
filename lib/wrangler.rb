module Wrangler

  class Client
    def Client.dnat_client
      conn = Faraday.new(url: Air.config.dnat.url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger 
        faraday.adapter Faraday.default_adapter
        faraday.basic_auth(Air.config.dnat.user,Air.config.dnat.password)
      end
    end
  end
end