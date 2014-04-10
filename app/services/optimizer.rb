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
    appl_manager = ApplianceVmsManager.new(appliance)

    if appliance.virtual_machines.blank?
      vm_to_be_reused = nil
      if appl_manager.can_reuse_vm? && !(vm_to_be_reused = find_vm_that_can_be_reused(appliance)).nil?
        appl_manager.reuse_vm!(vm_to_be_reused)
      else
        tmpls = VirtualMachineTemplate.where(appliance_type: appliance.appliance_type, state: 'active')
        if tmpls.blank?
          appliance.state = :unsatisfied
          err_msg = "No matching template was found for appliance #{appliance.name}"
          appliance.state_explanation = err_msg
          appliance.save
          Rails.logger.warn err_msg
        else
          tmpl, flavor = select_tmpl_and_flavor(tmpls, preferences(appliance))
          if flavor.nil?
            appliance.state = :unsatisfied
            err_msg = "No matching flavor was found for appliance #{appliance.name}"
            appliance.state_explanation = err_msg
            Rails.logger.warn err_msg
          else
            vm_name = appliance.name.blank? ? appliance.appliance_type.name : appliance.name
            appl_manager.spawn_vm!(tmpl, flavor, vm_name)
          end
        end
      end
      unless appl_manager.save
        Rails.logger.error appliance.errors.to_json
      end
    end
  end

  def not_enough_funds(appliance)
    appliance.state = :unsatisfied
    appliance.billing_state = "expired"
    appliance.state_explanation = 'Not enough funds'
  end

  def preferences(appl)
    props = appl.dev_mode_property_set
    props ? {preference_cpu: props.preference_cpu, preference_memory: props. preference_memory, preference_disk: props. preference_disk} : {}
  end

  def find_vm_that_can_be_reused(appliance)
    # TODO ask PN for help SQL => HAVING COUNT() < MAX_APPLIANCES_NO
    VirtualMachine.manageable.joins(:appliances).where('appliances.appliance_configuration_instance_id = ?', appliance.appliance_configuration_instance_id).reject {|vm| vm.appliances.count >= Air.config.optimizer.max_appl_no or vm.appliances.first.development?}.first
    #VirtualMachine.joins(appliances: :appliance_configuration_instance).where('appliance_configuration_instances.payload = ?', appliance.appliance_configuration_instance.payload).reject {|vm| vm.appliances.count >= Air.config.optimizer.max_appl_no}.first
  end

  def terminate_unused_vms
    #logger.info 'Terminating unused vms'
    # TODO ask PN for better query
    VirtualMachine.manageable.where('id NOT IN (SELECT DISTINCT(virtual_machine_id) FROM deployments)').each {|vm| vm.destroy }
  end

  def select_tmpl_and_flavor(tmpls, options={})
    required_mem = options[:preference_memory] || tmpls.first.appliance_type.preference_memory || (tmpls.first.compute_site.public? ? 1536 : 512)
    required_cores = options[:preference_cpu] || tmpls.first.appliance_type.preference_cpu || 1
    required_disk = options[:preference_disk] || tmpls.first.appliance_type.preference_disk || 0
    opt_flavors_and_tmpls_map = {}
    tmpls.each do |tmpl|
      opt_fl = (min_elements_by(tmpl.compute_site.virtual_machine_flavors.select {|f| (f.supported_architectures == 'i386_and_x86_64' || f.supported_architectures == tmpl.architecture) && f.memory >= required_mem && f.cpu >= required_cores && f.hdd >= required_disk}) {|f| f.hourly_cost}).sort!{ |x,y| y.memory <=> x.memory }.last
      opt_flavors_and_tmpls_map[opt_fl] = tmpl if opt_fl
    end
    globally_opt_flavor = (min_elements_by(opt_flavors_and_tmpls_map.keys){|f| f.hourly_cost}).sort{ |x,y| x.memory <=> y.memory }.last
    [opt_flavors_and_tmpls_map[globally_opt_flavor], globally_opt_flavor]
  end


end