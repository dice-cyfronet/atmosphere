module Atmosphere
  class VmLoadMonitoringWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options retry: false

    def perform
      Rails.logger.debug { "Started load monitoring at #{Time.now}" }
      VirtualMachine.monitorable.each do |vm|
        metrics = vm.current_load_metrics
        vm.save_load_metrics(metrics)
      end
      Rails.logger.debug { "Finished load monitoring at #{Time.now}" }
    end
  end
end