require 'wrangler'

class WranglerEraserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :wrangler

  def perform(ip, port = nil, protocol = nil)
    dnat_client = Wrangler::Client.dnat_client
    resp = dnat_client.delete(build_path_for_params(ip, port, protocol))
  end

  def build_path_for_params(ip, port, protocol)
    "/dnat/#{ip}#{'/' + port.to_s if port}#{'/' + protocol if protocol}"
  end

end