class Optimizer
  include Singleton

  # TODO move to air.yml
  # max number of appliances that use single vm
  MAX_APPLIANCES_NO = 5

  # Runs optimization of resource allocation (i.e. virtual machines in cloud).
  # If hint is provided it is used to narrow the scope of optimization.
  # Hint can be provided in a hash with one of the following keys:
  # :appliance_id DB id of the appliance that was created. Optimization only takes care of finding a vm or creating a new one for given appliance.
  def run(hint)
    satisfy_appliance(hint[:appliance_id]) if hint[:appliance_id]
  end

  private
  def satisfy_appliance(appliance_id)
    appliance = Appliance.find(appliance_id)
    if appliance.virtual_machines.blank?
      if appliance.appliance_type.shared and not (vm_to_be_resued = fing_vm_that_can_be_resued(appliance)).nil?
        appliance.virtual_machines << vm_to_be_resued
        appliance.save
      else
        # TODO orders templates based on cost model
        tmpl = VirtualMachineTemplate.where(appliance_type: appliance.appliance_type).first
        if tmpl.blank?
          # raise error
        else
          VirtualMachine.create(name: appliance.appliance_type.name, source_template: tmpl, appliance_ids: [appliance_id])
        end
      end
    end
  end

  def find_vm_that_can_be_reused(appliance)
    # TODO ask PN for help SQL => HAVING COUNT() < MAX_APPLIANCES_NO
    VirtualMachine.joins(:appliances).where('appliances.appliance_configuration_instance_id = ?', appliance.appliance_configuration_instance_id).reject {|vm| vm.appliances.count > MAX_APPLIANCES_NO}
  end

end