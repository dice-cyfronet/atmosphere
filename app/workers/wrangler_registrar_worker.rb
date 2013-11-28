require 'wrangler'

class WranglerRegistrarWorker
  include Sidekiq::Worker
  include Wrangler

  sidekiq_options queue: :wrangler

  def perform(vm_id)
    vm = VirtualMachine.find vm_id
    pmts = nil
    if (vm.appliances.first and vm.appliances.first.development?)
      pmts = vm.appliances.first.dev_mode_property_set.port_mapping_templates
    else
      pmts = vm.appliance_type.port_mapping_templates if vm.appliance_type
    end
    return unless pmts and vm.ip
    already_added_mapping_tmpls = vm.port_mappings ? vm.port_mappings.select {|m| m.port_mapping_template} : [] 
    pmt_map = {}
    to_add = (pmts.select {|e| e.application_protocol.none?} - already_added_mapping_tmpls).collect {|pmt|
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