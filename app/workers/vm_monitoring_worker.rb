class VmMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring

  def perform(site_id)
    site = ComputeSite.find(site_id)
    update_vms(site, site.cloud_client.servers)
  end

  private

  def update_vms(site, servers)
    all_site_vms = site.virtual_machines.to_a
    servers.each do |server|
      updated_vm = VmUpdater.new(site, server).update
      all_site_vms.delete updated_vm
    end

    #remove deleted VMs without calling cloud callbacks
    all_site_vms.each { |vm| vm.destroy(false) }
  end
end