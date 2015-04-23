module Atmosphere
  module Cloud
    class SatisfyAppliance
      def initialize(appliance)
        @appliance = appliance
      end

      def execute
        action = Action.create(appliance: appliance,
                               action_type: :satisfy_appliance)
        action.log('Satisfying appliance started')

        logger.info { "Satisfying appliance with #{appliance.id} id started" }
        appl_manager = ApplianceVmsManager.new(appliance)
        optimization_strategy = appliance.optimization_strategy

        if appliance.virtual_machines.blank?
          vm_to_be_reused = nil
          if optimization_strategy.can_reuse_vm? && !(vm_to_be_reused = optimization_strategy.vm_to_reuse).nil?
            logger.info { " - Reusing #{vm_to_be_reused.id_at_site} for #{appliance.id}" }
            appl_manager.reuse_vm!(vm_to_be_reused)
            logger.info { " - #{vm_to_be_reused.id_at_site} vm reused for #{appliance.id}" }
          else
            optimization_strategy.new_vms_tmpls_and_flavors.each do |tmpl_and_flavor|
              tmpl = tmpl_and_flavor[:template]
              flavor = tmpl_and_flavor[:flavor]
              if tmpl.blank?
                appliance.state = :unsatisfied
                err_msg = "No matching template was found for appliance #{appliance.name}"
                appliance.state_explanation = err_msg
                appliance.save
                logger.warn {
                  " - No matching template was found for appliance with #{appliance.id} id"
                }
              elsif flavor.nil?
                appliance.state = :unsatisfied
                err_msg = "No matching flavor was found for appliance #{appliance.name}"
                appliance.state_explanation = err_msg
                logger.warn {
                  " - No matching flavor was found for appliance with #{appliance.id} id"
                }
              else
                vm_name = appliance.name.blank? ? appliance.appliance_type.name : appliance.name
                logger.info { " - Spawning new VM from #{tmpl.id_at_site} with #{flavor.id_at_site} flavor for appliance with #{appliance.id} id" }
                appl_manager.spawn_vm!(tmpl, flavor, vm_name)
                logger.info { " - New VM from #{tmpl.id_at_site} with #{flavor.id_at_site} flavor started for appliance with #{appliance.id} id" }
              end
            end
          end
          unless appl_manager.save
            logger.error appliance.errors.to_json
          end
        end

        action.log('Satisfying appliance finished')
        logger.info { "Satisfying appliance with #{appliance.id} id ended" }
      end

      private

      attr_reader :appliance

      def logger
        Atmosphere.optimizer_logger
      end
    end
  end
end
