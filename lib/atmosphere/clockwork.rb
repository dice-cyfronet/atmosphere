module Atmopshere
  module Clockwork
    extend ActiveSupport::Concern

    included do
      every(1.minute, 'monitoring.templates') do
        Atmosphere::ComputeSite.active.select(:id, :name).each do |cs|
          Rails.logger.debug "Creating templates monitoring task for #{cs.name}"
          Atmosphere::VmTemplateMonitoringWorker.perform_async(cs.id)
        end
      end

      every(30.seconds, 'monitoring.vms') do
        Atmosphere::ComputeSite.active.select(:id, :name).each do |cs|
          Rails.logger.debug "Creating vms monitoring task for #{cs.name}"
          Atmosphere::VmMonitoringWorker.perform_async(cs.id)
        end
      end

      every(Atmosphere.monitoring.query_interval.minutes, 'monitoring.load') do
        Atmosphere::VmLoadMonitoringWorker.perform_async
      end

      every(120.minutes, 'monitoring.flavors') do
        Atmosphere::FlavorWorker.perform_async
      end

      every(60.minutes, 'billing.bill') do
        Atmosphere::BillingWorker.perform_async
      end

      every(Atmosphere.url_monitoring.pending.seconds, 'monitoring.http_mappings.pending') do
        Atmosphere::HttpMappingMonitoringWorker.perform_async(:pending)
      end

      every(Atmosphere.url_monitoring.ok.seconds, 'monitoring.http_mappings.ok') do
        Atmosphere::HttpMappingMonitoringWorker.perform_async(:ok)
      end

      every(Atmosphere.url_monitoring.lost.seconds, 'monitoring.http_mappings.lost') do
        Atmosphere::HttpMappingMonitoringWorker.perform_async(:lost)
      end
    end
  end
end