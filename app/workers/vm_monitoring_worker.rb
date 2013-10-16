class VmMonitoringWorker
  include Sidekiq::Worker
  include Cloud

  sidekiq_options queue: :monitoring

  def perform(site_id)
    site = ComputeSite.find(site_id)
    client = VmTemplateMonitoringWorker.get_cloud_client_for_site(site.site_id)
    update_vms(site, client.servers)
  end

  def update_vms(site, servers)
    all_site_vms = site.virtual_machines.to_a
    servers.each do |server|
      vm = site.virtual_machines.find_or_initialize_by(id_at_site: server.id)
      vm.source_template = VirtualMachineTemplate.find_by(compute_site: site, id_at_site: server.image['id'])
      vm.name = server.name
      vm.state = server.state.downcase.to_sym

      all_site_vms.delete vm

      unless vm.save
        error("unable to create/update #{vm.id} virtual machine because: #{vm.errors.to_json}")
      end

      #remove deleted templates
    all_site_vms.each { |vm| vm.destroy }
    end
  end

  def error(message)
    Rails.logger.error "MONITORING: #{message}"
  end
end