require 'wrangler'

class WranglerRegistrarWorker
  include Sidekiq::Worker

  sidekiq_options queue: :wrangler_registrar

  def perform(vm)
    return unless vm.appliance_type.port_mapping_templates
    already_added_mapping_tmpls = vm.port_mappings ? vm.port_mappings.select {|m| m.port_mapping_template} : [] 
    (vm.appliance_type.port_mapping_templates - already_added_mapping_tmpls).each do |pmt|
      added_mapping_data = add(vm.ip, pmt.transport_protocol, pmt.target_port)
      added_mapping_data[:port_mapping_template_id] = pmt.id
      added_mapping_data[:virtual_machine_id] = vm.id
      pm = PortMapping.create(added_mapping_data)
    end
  end
  
  # TODO refactor to call wrangler once for many redirections

  def add(ip, protocol, port)
    dnat_client = Wrangler::Client.dnat_client
    resp = dnat_client.post do |req|
      req.url "/dnat/#{ip}"
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate [{proto: protocol, port: port}]
    end
    # [{\"privIp\":\"169.1.2.3\",\"pubPort\":11921,\"proto\":\"tcp\",\"privPort\":8888,\"pubIp\":\"149.156.10.132\"}]
    added_mapping_info = JSON.parse(resp.body).first
    {public_ip: added_mapping_info['pubIp'], source_port: added_mapping_info['pubPort']}
  end

end