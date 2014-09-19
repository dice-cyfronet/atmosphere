# require 'config/boot'
# require 'config/environment'

require_relative "../config/boot"
require_relative "../config/environment"

module Clockwork

  every(1.minute, 'monitoring.templates') do
    ComputeSite.active.select(:id, :name).each do |cs|
      Rails.logger.debug "Creating templates monitoring task for #{cs.name}"
      VmTemplateMonitoringWorker.perform_async(cs.id)
    end
  end

  every(30.seconds, 'monitoring.vms') do
    ComputeSite.active.select(:id, :name).each do |cs|
      Rails.logger.debug "Creating vms monitoring task for #{cs.name}"
      VmMonitoringWorker.perform_async(cs.id)
    end
  end

  every(Air.config.monitoring.query_interval.minutes, 'monitoring.load') do
    VmLoadMonitoringWorker.perform_async
  end

  every(120.minutes, 'monitoring.flavors') do
    FlavorWorker.perform_async
  end

  every(60.minutes, 'billing.bill') do
    BillingWorker.perform_async
  end

  every(Air.config.http_mapping_monitor.pending, 'monitoring.http_mappings.pending') do
    HttpMappingMonitoringWorker.perform_async(:pending)
  end

  every(Air.config.http_mapping_monitor.ok, 'monitoring.http_mappings.ok') do
    HttpMappingMonitoringWorker.perform_async(:ok)
  end

  every(Air.config.http_mapping_monitor.lost, 'monitoring.http_mappings.lost') do
    HttpMappingMonitoringWorker.perform_async(:lost)
  end

  every(5.minutes, 'cleaning mi loging strategy cache') do
    MiCacheCleanerWorker.perform_async
  end
end