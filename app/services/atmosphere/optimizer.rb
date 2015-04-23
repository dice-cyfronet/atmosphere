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
      Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute
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

      action = Action.create(appliance: appliance, action_type: :scale)

      optimization_strategy = appliance.optimization_strategy
      appl_manager = ApplianceVmsManager.new(appliance)
      if optimization_strategy.can_scale_manually?
        action.log('Scaling started')
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
        action.log('Scaling finished')
      else
        action.log('Scaling not allowed')
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
