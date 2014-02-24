class VmMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring
  sidekiq_options :retry => false

  def initialize(vm_updater_class=VmUpdater)
    @vm_updater_class = vm_updater_class
  end

  def perform(site_id)
    begin
      site = ComputeSite.find(site_id)
      update_vms(site, site.cloud_client.servers)
    rescue Excon::Errors::HTTPStatusError => e
      Rails.logger.error "Unable to perform VMs monitoring job: #{e}"
    end
  end

  private

  attr_reader :vm_updater_class

  def update_vms(site, servers)
    all_site_vms = site.virtual_machines.to_a
    servers.each do |server|
      updated_vm = vm_updater_class.new(site, server).update
      all_site_vms.delete updated_vm
    end

    #remove deleted VMs without calling cloud callbacks
    all_site_vms.each { |vm| vm.destroy(false) }
  end
end