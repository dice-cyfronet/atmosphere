module Atmosphere
  class VmMonitoringWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options retry: false

    def initialize(vm_updater_class=VmUpdater, vm_destroyer_class=VmDestroyer)
      @vm_updater_class = vm_updater_class
      @vm_destroyer_class = vm_destroyer_class
    end

    def perform(tenant_id)
      begin
        logger.debug { "#{jid}: starting VM monitoring worker for tenant #{tenant_id}" }
        tenant = Tenant.find(tenant_id)
        logger.debug { "#{jid}: getting servers state for tenant #{tenant_id} from tenant" }
        update_vms(tenant, tenant.cloud_client.servers)
        logger.debug { "#{jid}: VM monitoring finished for tenant #{tenant_id}" }
      rescue Excon::Errors::HTTPStatusError => e
        logger.error "Unable to perform VMs monitoring job: #{e}"
      end
    end

    private

    attr_reader :vm_updater_class, :vm_destroyer_class

    def update_vms(tenant, servers)
      logger.debug { "#{jid}: updating information about VMs" }
      all_tenant_vms = tenant.virtual_machines.to_a
      servers.each do |server|
        updated_vm = vm_updater_class.new(tenant, server).execute
        all_tenant_vms.delete updated_vm
      end

      #remove deleted VMs without calling cloud callbacks
      all_tenant_vms.each do |vm|
        vm_destroyer_class.new(vm).destroy(false) if vm.old?
      end
    end

    def logger
      Atmosphere.monitoring_logger
    end
  end
end