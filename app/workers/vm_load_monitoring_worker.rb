require 'zabbix'

class VmLoadMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring
  sidekiq_options :retry => false

  def perform
    VirtualMachine.all.each do |vm|
      if vm.managed_by_atmosphere && vm.zabbix_host_id
        metrics = vm.current_load_metrics 
        vm.save_load_metrics(metrics)
      end
    end
  end
end