module Wrangler

  MIN_PORT_NO = 0
  MAX_PORT_NO = 65535

  class Client
    def Client.dnat_client
      conn = Faraday.new(url: Air.config.dnat.url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger 
        faraday.adapter Faraday.default_adapter
        faraday.basic_auth(Air.config.dnat.user,Air.config.dnat.password)
      end
    end

    def check_port(port)
      raise ForbiddenPortNumber.new("Port #{port} cannot be redirected by wrangler. Ports 0..1023 are forbidden.")
    end
  end
end