module Atmosphere
  module Cloud
    class ScaleAppliance
      def initialize(appliance, quantity)
        @appliance = appliance
        @quantity = quantity
      end

      def execute
        if optimization_strategy.can_scale_manually?
          action.log(I18n.t('scale_appliance.start'))
          if quantity > 0
            vms = optimization_strategy.vms_to_start(quantity)
            appl_manager.start_vms!(vms)
          else
            if appliance.virtual_machines.count > quantity.abs
              vms = optimization_strategy.vms_to_stop(-quantity)
              appl_manager.stop_vms!(vms)
            else
              appl_manager.unsatisfied(I18n.t('scale_appliance.to_small_vms'))
            end
          end
          action.log(I18n.t('scale_appliance.end'))
        else
          action.log('Scaling not allowed')
          #TODO - verify if the state unsatisfied is any meaningful in this case
          appl_manager.
            unsatisfied(I18n.t('scale_appliance.not_allowed_description'))
        end
        appl_manager.save
      end

      private

      attr_reader :appliance, :quantity

      def action
        @action ||= Action.create(appliance: appliance, action_type: :scale)
      end

      def optimization_strategy
        @optimization_strategy ||= appliance.optimization_strategy
      end

      def appl_manager
        @appl_manager ||= ApplianceVmsManager.new(appliance)
      end
    end
  end
end
