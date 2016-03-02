module Atmosphere
  class RecordVmLoad
    def initialize(vm)
      @vm = vm
    end

    def execute
      save_metrics(current_load_metrics) if monitored?
    end

    private

    def monitored?
      @vm.managed_by_atmosphere && @vm.monitoring_id
    end

    def current_load_metrics
      if @vm.monitoring_id
        metrics = monitoring_client.host_metrics(@vm.monitoring_id)
        metrics.collect_last if metrics
      end
    end

    def save_metrics(metrics)
      return unless metrics
      cpu_load_1 = 'Processor load (1 min average per core)'
      cpu_load_5 = 'Processor load (5 min average per core)'
      cpu_load_15 = 'Processor load (15 min average per core)'

      total_mem = 'Total memory'
      available_mem = 'Available memory'

      metrics_hash = {}
      metrics.each { |m| metrics_hash.merge!(m) }

      @vm.appliances.each do |appl|
        write_point(appl, 'cpu_load_1', metrics_hash[cpu_load_1])
        write_point(appl, 'cpu_load_5', metrics_hash[cpu_load_5])
        write_point(appl, 'cpu_load_15', metrics_hash[cpu_load_15])
        if metrics_hash.fetch(total_mem, 0) > 0 &&
            metrics_hash.fetch(available_mem, 0) > 0
          mem_usage = (metrics_hash[total_mem] - metrics_hash[available_mem]) /
                      metrics_hash[total_mem]
          write_point(appl, 'memory_usage', mem_usage)
        end
      end
    end

    def write_point(appl, key, value)
      metrics_store.write_point(key,
                                appliance_set_id: appl.appliance_set_id,
                                appliance_id: appl.id,
                                virtual_machine_id: @vm.uuid,
                                value: value)
    end

    def monitoring_client
      Atmosphere.monitoring_client
    end

    def metrics_store
      Atmosphere.metrics_store
    end
  end
end
