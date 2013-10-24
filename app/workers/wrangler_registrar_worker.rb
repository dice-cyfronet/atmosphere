require 'wrangler'

class WranglerRegistrarWorker
  include Sidekiq::Worker

  sidekiq_options queue: :wrangler_registrar

  def perform(ip, protocol, port)
    add(ip, protocol, port)
  end
  
  def add(ip, protocol, port)
    dnat_client = Wrangler::Client.dnat_client
    resp = dnat_client.post do |req|
      req.url "/dnat/#{ip}"
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate [{proto: protocol, port: port}]
    end
  end

end