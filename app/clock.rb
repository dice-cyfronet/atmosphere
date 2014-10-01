# require 'config/boot'
# require 'config/environment'

require_relative "../config/boot"
require_relative "../config/environment"

module Clockwork

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

  every(Air.config.monitoring.query_interval.minutes, 'monitoring.load') do
    Atmosphere::VmLoadMonitoringWorker.perform_async
  end

  every(120.minutes, 'monitoring.flavors') do
    Atmosphere::FlavorWorker.perform_async
  end

  every(60.minutes, 'billing.bill') do
    Atmosphere::BillingWorker.perform_async
  end

  every(Air.config.http_mapping_monitor.pending.to_i.seconds, 'monitoring.http_mappings.pending') do
    Atmosphere::HttpMappingMonitoringWorker.perform_async(:pending)
  end

  every(Air.config.http_mapping_monitor.ok.to_i.seconds, 'monitoring.http_mappings.ok') do
    Atmosphere::HttpMappingMonitoringWorker.perform_async(:ok)
  end

  every(Air.config.http_mapping_monitor.lost.to_i.seconds, 'monitoring.http_mappings.lost') do
    Atmosphere::HttpMappingMonitoringWorker.perform_async(:lost)
  end

  every(5.minutes, 'cleaning mi loging strategy cache') do
    Atmosphere::MiCacheCleanerWorker.perform_async
  end
end