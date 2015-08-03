module Atmosphere
  module OptimizationStrategy
    class CpuLoad < OptimizationStrategy::Default
      def monitor_vms?
        true
      end

      def handle_event(hash)
        logger.info "Received complex event: #{hash}"
      end

      def event_definitions
        time_window = 300
        interval = 600
        {
          simple_event: {
            name: 'CpuLoad',
            properties: {
              'vmUuid': 'String',
              'cpuLoad': 'float'
            }
          },
          complex_event:
            "select avg(cpuLoad), vmUuid"\
            " from CpuLoad.win:time(#{time_window} sec)"\
            " having avg(cpuLoad) > 0.8 output first every #{interval} seconds"
        }
      end
      private
      def logger
        Atmosphere.complex_event_logger
      end
    end
  end
end
