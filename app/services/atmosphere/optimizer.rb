module Atmosphere
  class Optimizer
    include Singleton

    # Runs optimization of resource allocation (i.e. virtual machines in cloud).
    # If hint is provided it is used to narrow the scope of optimization.
    # Hint can be provided in a hash with one of the following keys:
    # :appliance_id DB id of the appliance that was created. Optimization only akes care of finding a vm or creating a new one for given appliance.
    def run(hint)
      satisfy_appliance(hint[:created_appliance]) if hint[:created_appliance]
      terminate_unused_vms if hint[:destroyed_appliance]
      scale(hint[:scaling]) if hint[:scaling]
    end

    #private
    def satisfy_appliance(appliance)

      action = Action.create { |action|
        action.appliance = appliance
        action.type = :satisfy_appliance
      }

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

      logger.info { "Satisfying appliance with #{appliance.id} id ended" }
    end

    def terminate_unused_vms
      logger.info { "Terminating unused VMs started" }
      VirtualMachine.unused.each do |vm|
        logger.info { " - Destroying #{vm.id_at_site} VM scheduled" }
        Cloud::VmDestroyWorker.perform_async(vm.id)
      end
      logger.info { "Terminating unused VMs ended" }
    end

    def select_tmpl_and_flavor(tmpls, options={})
      tmpl_and_flavor = select_tmpls_and_flavors(tmpls, options).first
      [tmpl_and_flavor[:template], tmpl_and_flavor[:flavor]]
    end

    def select_tmpls_and_flavors(tmpls, options={})
      OptimizationStrategy::Default.select_tmpls_and_flavors(tmpls, options)
    end

    def scale(hint)
      appliance = hint[:appliance]
      quantity = hint[:quantity]
      action = Action.create { |action|
        action.appliance = appliance
        action.type = :scale
      }
      optimization_strategy = appliance.optimization_strategy
      appl_manager = ApplianceVmsManager.new(appliance)
      if optimization_strategy.can_scale_manually?
        if quantity > 0
          vms = optimization_strategy.vms_to_start(quantity)
          appl_manager.start_vms!(vms)
        else
          if appliance.virtual_machines.count > quantity.abs
            vms = optimization_strategy.vms_to_stop(-quantity)
            appl_manager.stop_vms!(vms)
          else
            appl_manager.unsatisfied("Not enough vms to scale down")
          end
        end
      else
        #TODO - verify if the state unsatisfied is any meaningful in this case
        appl_manager.unsatisfied("Chosen optimization strategy does not allow for manual scaling")
      end
      appl_manager.save
    end

    private

    def logger
      Atmosphere.optimizer_logger
    end
  end
end
