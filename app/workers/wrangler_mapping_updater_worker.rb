require 'wrangler'

class WranglerMappingUpdaterWorker
  include Sidekiq::Worker
  include Wrangler

  sidekiq_options queue: :wrangler

  def perform(vm_id, pmt_id)
    vm = VirtualMachine.find(vm_id)
    pmt = PortMappingTemplate.find(pmt_id)


    pm_to_update = vm.port_mappings.select{|pm| pm.port_mapping_template == pmt}.first
    return unless pm_to_update
    resp = Wrangler::Client.dnat_client.delete "/dnat/#{vm.ip}/#{pmt.target_port}"
    if not resp.status == 204
      Rails.logger.error "Wrangler returned #{resp.status} #{resp.body} when trying to remove redirection for IP #{vm.ip}:#{pmt.target_port}"
      return
    end
    resp = Wrangler::Client.dnat_client.post "/dnat/#{vm.ip}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate [{proto: pmt.transport_protocol, port: pmt.target_port}]
    end
    if not resp.status == 200
      Rails.logger.error "Wrangler returned #{resp.status} #{resp.body} when trying to add redirections for VM #{vm.uuid} with IP #{vm.ip}. Requested redirections: [{:proto=>\"#{pmt.transport_protocol}\", :port=>#{pmt.target_port}}]"
    end
  end
end