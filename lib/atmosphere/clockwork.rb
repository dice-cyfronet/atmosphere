module Atmopshere
  module Clockwork
    extend ActiveSupport::Concern

    included do
      every(Atmosphere.monitoring.intervals.vmt, 'monitoring.templates') do
        action_on_actice_cses('templates monitoring',
                              Atmosphere::VmTemplateMonitoringWorker)
      end

      every(Atmosphere.monitoring.intervals.vm, 'monitoring.vms') do
        action_on_actice_cses('vms monitoring',
                              Atmosphere::VmMonitoringWorker)
      end

      every(Atmosphere.monitoring.intervals.load, 'monitoring.load') do
        Atmosphere::VmLoadMonitoringWorker.perform_async
      end

      every(Atmosphere.monitoring.intervals.flavor, 'monitoring.flavors') do
        Atmosphere::FlavorWorker.perform_async
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

      def self.action_on_actice_cses(name, task)
        Atmosphere::ComputeSite.active.select(:id, :name).each do |cs|
          Rails.logger.debug "Creating #{name} task for #{cs.name}"
          task.perform_async(cs.id)
        end
      end
    end
  end
end
