require 'wrangler'

class WranglerRegistrarWorker
  include Sidekiq::Worker

  sidekiq_options queue: :wrangler_registrar

  MIN_PORT_NO = 0
  MAX_PORT_NO = 65535

  def perform(vm)
    return unless vm.appliance_type.port_mapping_templates and vm.ip
    already_added_mapping_tmpls = vm.port_mappings ? vm.port_mappings.select {|m| m.port_mapping_template} : [] 
    pmt_map = {}
    to_add = (vm.appliance_type.port_mapping_templates.select {|e| e.application_protocol.none?} - already_added_mapping_tmpls).collect {|pmt|
      if not pmt.target_port.in? MIN_PORT_NO..MAX_PORT_NO
        Rails.logger.error "Error when trying to add redirections for VM #{vm.uuid} with IP #{vm.ip}. Requested redirection for forbidden port #{pmt.target_port}"
        return
      end
      pmt_map[pmt.target_port] = pmt
      {proto: pmt.transport_protocol, port: pmt.target_port}
    }
    return if to_add.blank?
    resp = Wrangler::Client.dnat_client.post "/dnat/#{vm.ip}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate to_add
    end
    if resp.status == 200
      JSON.parse(resp.body).collect { |e| PortMapping.create(port_mapping_template: pmt_map[e['privPort']], virtual_machine: vm, public_ip: e['pubIp'], source_port: e['pubPort']) }
    else
      Rails.logger.error "Wrangler returned #{resp.status} #{resp.body} when trying to add redirections for VM #{vm.uuid} with IP #{vm.ip}. Requested redirections: #{to_add}"
    end
  end

end