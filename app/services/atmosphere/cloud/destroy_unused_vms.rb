module Atmosphere
  module Cloud
    class DestroyUnusedVms
      def execute
        logger.info(I18n.t('destroy_vms.start'))
        VirtualMachine.unused.each do |vm|
          logger.info { I18n.t('destroy_vms.perform', name: vm.id_at_site) }
          VmDestroyWorker.perform_async(vm.id)
        end
        logger.info(I18n.t('destroy_vms.end'))
      end

      private

      def logger
        Atmosphere.optimizer_logger
      end
    end
  end
end
