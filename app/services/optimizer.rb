class Optimizer
  include Singleton


  # Runs optimization of resource allocation (i.e. virtual machines in cloud).
  # If hint is provided it is used to narrow the scope of optimization.
  # Hint can be provided in a hash with one of the following keys:
  # :appliance_id DB id of the appliance that was created. Optimization only takes care of finding a vm or creating a new one for given appliance.
  def run(hint)
    satisfy_appliance(hint[:created_appliance]) if hint[:created_appliance]
    terminate_unused_vms if hint[:destroyed_appliance]
  end

  private
  def satisfy_appliance(appliance)
    if appliance.virtual_machines.blank?
      vm_to_be_reused = nil
      if appliance.appliance_type.shared and not (vm_to_be_reused = find_vm_that_can_be_reused(appliance)).nil?
        appliance.virtual_machines << vm_to_be_reused
        appliance.state = :satisfied
        unless appliance.save
          Rails.logger.error appliance.errors.to_json
        end
        ProxyConfWorker.regeneration_required(vm_to_be_reused.compute_site)
      else
        # TODO orders templates based on cost model
        tmpl = VirtualMachineTemplate.where(appliance_type: appliance.appliance_type).first
        if tmpl.blank?
          appliance.state = :unsatisfied
          appliance.save
          Rails.logger.warn "No template for instantiating a vm for appliance #{appliance.id} was found"
        else
          VirtualMachine.create(name: appliance.appliance_type.name, source_template: tmpl, appliance_ids: [appliance.id], state: :build)
          appliance.state = :satisfied
          appliance.save
        end
      end
    end
  end

  def find_vm_that_can_be_reused(appliance)
    # TODO ask PN for help SQL => HAVING COUNT() < MAX_APPLIANCES_NO
    VirtualMachine.joins(:appliances).where('appliances.appliance_configuration_instance_id = ?', appliance.appliance_configuration_instance_id).reject {|vm| vm.appliances.count >= Air.config.optimizer.max_appl_no}.first
  end

  def terminate_unused_vms
    #logger.info 'Terminating unused vms'
    # TODO ask PN for better query
    VirtualMachine.where('id NOT IN (SELECT DISTINCT(virtual_machine_id) FROM appliances_virtual_machines)').each {|vm| vm.destroy }
  end

end