module Atmosphere
  class VmMonitoringWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options :retry => false

    def initialize(vm_updater_class=VmUpdater, vm_destroyer_class=VmDestroyer)
      @vm_updater_class = vm_updater_class
      @vm_destroyer_class = vm_destroyer_class
    end

    def perform(site_id)
      begin
        logger.debug { "#{jid}: starting VM monitoring worker for site #{site_id}" }
        site = ComputeSite.find(site_id)
        logger.debug { "#{jid}: getting servers state for site #{site_id} from compute site" }
        update_vms(site, site.cloud_client.servers)
        logger.debug { "#{jid}: VM monitoring finished for site #{site_id}" }
      rescue Excon::Errors::HTTPStatusError => e
        logger.error "Unable to perform VMs monitoring job: #{e}"
      end
    end

    private

    attr_reader :vm_updater_class, :vm_destroyer_class

    def update_vms(site, servers)
      logger.debug { "#{jid}: updating information about VMs" }
      all_site_vms = site.virtual_machines.to_a
      servers.each do |server|
        updated_vm = vm_updater_class.new(site, server).update
        all_site_vms.delete updated_vm
      end

      #remove deleted VMs without calling cloud callbacks
      all_site_vms.each do |vm|
        vm_destroyer_class.new(vm).destroy(false) if vm.old?
      end
    end

    def logger
      Atmosphere.monitoring_logger
    end
  end
end