require 'utils'

class Optimizer
  include Singleton
  include Utils


  # Runs optimization of resource allocation (i.e. virtual machines in cloud).
  # If hint is provided it is used to narrow the scope of optimization.
  # Hint can be provided in a hash with one of the following keys:
  # :appliance_id DB id of the appliance that was created. Optimization only takes care of finding a vm or creating a new one for given appliance.
  def run(hint)
    satisfy_appliance(hint[:created_appliance]) if hint[:created_appliance]
    terminate_unused_vms if hint[:destroyed_appliance]
  end

  #private
  def satisfy_appliance(appliance)
    logger.info { "Satisfying appliance with #{appliance.id} id started" }
    appl_manager = ApplianceVmsManager.new(appliance)
    optimization_strategy = appliance.optimization_strategy

    if appliance.virtual_machines.blank?
      vm_to_be_reused = nil
      if appl_manager.can_reuse_vm? && !(vm_to_be_reused = optimization_strategy.vm_to_reuse).nil?
        logger.info { " - Reusing #{vm_to_be_reused.id_at_site} for #{appliance.id}" }
        appl_manager.reuse_vm!(vm_to_be_reused)
        logger.info { " - #{vm_to_be_reused.id_at_site} vm reused for #{appliance.id}" }
      else
        tmpl, flavor = optimization_strategy.new_vm_tmpl_and_flavor
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
      unless appl_manager.save
        logger.error appliance.errors.to_json
      end
    end

    logger.info { "Satisfying appliance with #{appliance.id} id ended" }
  end

  def terminate_unused_vms
    logger.info { "Terminating unused VMs started" }
    not_used_vms.each do |vm|
      logger.info { " - Destroying #{vm.id_at_site} VM" }
      vm.destroy
      logger.info { " - #{vm.id_at_site} VM destroyed" }
    end
    logger.info { "Terminating unused VMs ended" }
  end

  def select_tmpl_and_flavor(tmpls, options={})
    OptimizationStrategy::Default.select_tmpl_and_flavor(tmpls, options)
  end

  private

  def not_used_vms
    # TODO ask PN for better query
    VirtualMachine.manageable.where('id NOT IN (SELECT DISTINCT(virtual_machine_id) FROM deployments)')
  end

  def logger
    Air.optimizer_logger
  end
end