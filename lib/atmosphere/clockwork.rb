module Atmopshere
  module Clockwork
    extend ActiveSupport::Concern

    included do
      every(Atmosphere.monitoring.intervals.vmt, 'monitoring.templates') do
        action_on_active_tenants('templates monitoring',
                                 Atmosphere::VmTemplateMonitoringWorker)
      end

      every(Atmosphere.monitoring.intervals.vm, 'monitoring.vms') do
        action_on_active_tenants('vms monitoring',
                                 Atmosphere::VmMonitoringWorker)
      end

      every(Atmosphere.monitoring.intervals.load, 'monitoring.load') do
        Atmosphere::VmLoadMonitoringWorker.perform_async
      end

      every(Atmosphere.monitoring.intervals.flavor, 'monitoring.flavors') do
        action_on_active_tenants('flavor monitoring',
                                 Atmosphere::FlavorWorker)
      end

      every(60.minutes, 'billing.bill') do
        Atmosphere::BillingWorker.perform_async
      end

      every(Atmosphere.url_monitoring.pending.seconds,
            'monitoring.http_mappings.pending') do
        Atmosphere::HttpMappingMonitoringWorker.perform_async(:pending)
      end

      every(Atmosphere.url_monitoring.ok.seconds,
            'monitoring.http_mappings.ok') do
        Atmosphere::HttpMappingMonitoringWorker.perform_async(:ok)
      end

      every(Atmosphere.url_monitoring.lost.seconds,
            'monitoring.http_mappings.lost') do
        Atmosphere::HttpMappingMonitoringWorker.perform_async(:lost)
      end

      def self.action_on_active_tenants(name, task)
        Atmosphere::Tenant.active.select(:id, :name).each do |t|
          Rails.logger.debug "Creating #{name} task for #{t.name}"
          task.perform_async(t.id)
        end
      end
    end
  end
end
