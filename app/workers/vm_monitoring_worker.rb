class VmMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring
  sidekiq_options :retry => false

  def perform(site_id)
    begin
      site = ComputeSite.find(site_id)
      update_vms(site, site.cloud_client.servers)
    rescue Excon::Errors::HTTPStatusError => e
      Rails.logger.error "Unable to perform VMs monitoring job: #{e}"
    end
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