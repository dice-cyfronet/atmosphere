require 'wrangler'

class WranglerEraserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :wrangler

  def perform(ids)
    if ids.keys.size != 1
      Rails.logger.error "Invalid paramters given: #{ids} when trying to remove redirections."
      return
    end
    if ids[:vm_id]
      vm = VirtualMachine.find ids[:vm_id]
      return unless vm.ip and vm.port_mappings
      remove_all_for_vm vm
    elsif ids[:port_mapping_ids]
      remove_selected_port_mappings PortMapping.find ids[:port_mapping_ids]
    else
      Rails.logger.error "Invalid paramters given: #{ids} when trying to remove redirections."
    end
  end

  def build_path_for_params(ip, port, protocol)
    "/dnat/#{ip}#{'/' + port.to_s if port}#{'/' + protocol if protocol}"
  end

  private
  def build_req_params_msg(ip, port, protocol)
    "IP #{ip}#{', port ' + port.to_s if port}#{', protocol ' + protocol if protocol}"
  end

  def remove_all_for_vm(vm)
    if remove(vm.ip)
      vm.port_mappings.delete_all
    end
  end

  def remove_selected_port_mappings(port_mappings)
    port_mappings.each do |pm|
      if remove(pm.virtual_machine.ip, pm.port_mapping_template.target_port, pm.port_mapping_template.transport_protocol)
        pm.delete
      end
    end
  end

  def remove(ip, port = nil, protocol = nil)
    dnat_client = Wrangler::Client.dnat_client
    resp = dnat_client.delete(build_path_for_params(ip, port, protocol))
    if not resp.status == 204
      Rails.logger.error "Wrangler returned #{resp.status} when trying to remove redirections for #{build_req_params_msg(ip, port, protocol)}."
      return false
    end
    true
  end

end