module Atmosphere
  class VmLoadMonitoringWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options retry: false
    sidekiq_options unique: :until_executing

    def perform
      Rails.logger.debug { "Started load monitoring at #{Time.now}" }
      VirtualMachine.all.each { |vm| Atmosphere::RecordVmLoad.new(vm).execute }
      Rails.logger.debug { "Finished load monitoring at #{Time.now}" }
    end
  end
end
