module Wrangler

  MIN_PORT_NO = 0
  MAX_PORT_NO = 65535

  class Client
    def initialize(url, username, password)
      conn = Faraday.new(url: url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger 
        faraday.adapter Faraday.default_adapter
        faraday.basic_auth(username,password)
      end
    end

  end
end