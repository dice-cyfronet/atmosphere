module Atmosphere
  module OptimizationStrategy
    class CpuLoad < OptimizationStrategy::Default
      def monitor_vms?
        true
      end

      def handle_event(hash)
        nil
      end

      def event_definitions
        {
          simple_event: { name: 'CpuLoad', properties: {} },
          complex_event: ''
        }
      end

    end
  end
end
