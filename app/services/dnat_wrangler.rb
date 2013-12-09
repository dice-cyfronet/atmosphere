require 'wrangler'

class DnatWrangler
  include Singleton
  include Wrangler

  def remove_dnat_for_vm(vm)
    return true unless vm.ip and not vm.port_mappings.blank?
    remove(vm.ip)
  end

  def remove_port_mapping(pm)
    remove(pm.virtual_machine.ip, pm.port_mapping_template.target_port, pm.port_mapping_template.transport_protocol)
  end

  def build_path_for_params(ip, port, protocol)
    "/dnat/#{ip}#{'/' + port.to_s if port}#{'/' + protocol if protocol}"
  end

  def add_dnat_for_vm(vm, pmts)
    pmt_map = {}
    to_add = pmts.collect {|pmt|
      if not pmt.target_port.in? MIN_PORT_NO..MAX_PORT_NO
        Rails.logger.error "Error when trying to add redirections for VM #{vm.uuid} with IP #{vm.ip}. Requested redirection for forbidden port #{pmt.target_port}"
        return []
      end
      pmt_map[pmt.target_port] = pmt
      {proto: pmt.transport_protocol, port: pmt.target_port}
    }
    return [] if to_add.blank? or not vm.ip?
    resp = Wrangler::Client.dnat_client.post "/dnat/#{vm.ip}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate to_add
    end
    if resp.status == 200
      added_pms = JSON.parse(resp.body).collect { |e| {port_mapping_template: pmt_map[e['privPort']], virtual_machine: vm, public_ip: e['pubIp'], source_port: e['pubPort']} }
    else
      Rails.logger.error "Wrangler returned #{resp.status} #{resp.body} when trying to add redirections for VM #{vm.uuid} with IP #{vm.ip}. Requested redirections: #{to_add}"
      []
    end
  end

  def remove(ip, port = nil, protocol = nil)
    dnat_client = Wrangler::Client.dnat_client
    path = build_path_for_params(ip, port, protocol)
    resp = dnat_client.delete(path)
    if not resp.status == 204
      Rails.logger.error "Wrangler returned #{resp.status} when trying to remove redirections for #{build_req_params_msg(ip, port, protocol)}."
      return false
    end
    Rails.logger.info "[Wrangler] Deleted DNAT for #{path}"
    true
  end

  private

  def build_req_params_msg(ip, port, protocol)
    "IP #{ip}#{', port ' + port.to_s if port}#{', protocol ' + protocol if protocol}"
  end

end