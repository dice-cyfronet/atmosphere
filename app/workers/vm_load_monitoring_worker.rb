require 'zabbix'

class VmLoadMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring
  sidekiq_options :retry => false

  def perform
    Rails.logger.info "Started load monitoring at #{Time.now}"
    VirtualMachine.all.each do |vm|
      if vm.managed_by_atmosphere && vm.monitoring_id
        metrics = vm.current_load_metrics 
        vm.save_load_metrics(metrics)
      end
    end
    Rails.logger.info "Finished load monitoring at #{Time.now}"
  end
end