module Atmosphere
  class RecordVmLoad
    def initialize(vm)
      @vm = vm
    end

    def execute
      if monitored?
        metrics = @vm.current_load_metrics
        @vm.save_load_metrics(metrics)
      end
    end

    private

    def monitored?
      @vm.managed_by_atmosphere && @vm.monitoring_id
    end
  end
end
