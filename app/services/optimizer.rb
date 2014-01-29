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

  private
  def satisfy_appliance(appliance)
    if appliance.virtual_machines.blank?
      vm_to_be_reused = nil
      if not appliance.development? and appliance.appliance_type.shared and not (vm_to_be_reused = find_vm_that_can_be_reused(appliance)).nil?
        appliance.virtual_machines << vm_to_be_reused
        appliance.state = :satisfied
        ProxyConfWorker.regeneration_required(vm_to_be_reused.compute_site)
      else
        tmpls = VirtualMachineTemplate.where(appliance_type: appliance.appliance_type, state: 'active')
        if tmpls.blank?
          appliance.state = :unsatisfied
          err_msg = "No matching template was found for appliance #{appliance.name}"
          appliance.state_explanation = err_msg
          appliance.save
          Rails.logger.warn err_msg
        else
          tmpl, flavor = select_tmpl_and_flavor(tmpls)
          if flavor.nil?
            appliance.state = :unsatisfied
            err_msg = "No matching flavor was found for appliance #{appliance.name}"
            appliance.state_explanation = err_msg
            Rails.logger.warn err_msg
          else
            VirtualMachine.create(name: appliance.appliance_type.name, source_template: tmpl, appliance_ids: [appliance.id], state: :build, virtual_machine_flavor: flavor)
            appliance.state = :satisfied
          end
        end
      end
      unless appliance.save
        Rails.logger.error appliance.errors.to_json
      end
    end
  end

  def find_vm_that_can_be_reused(appliance)
    # TODO ask PN for help SQL => HAVING COUNT() < MAX_APPLIANCES_NO
    VirtualMachine.manageable.joins(:appliances).where('appliances.appliance_configuration_instance_id = ?', appliance.appliance_configuration_instance_id).reject {|vm| vm.appliances.count >= Air.config.optimizer.max_appl_no}.first
    #VirtualMachine.joins(appliances: :appliance_configuration_instance).where('appliance_configuration_instances.payload = ?', appliance.appliance_configuration_instance.payload).reject {|vm| vm.appliances.count >= Air.config.optimizer.max_appl_no}.first
  end

  def terminate_unused_vms
    #logger.info 'Terminating unused vms'
    # TODO ask PN for better query
    VirtualMachine.manageable.where('id NOT IN (SELECT DISTINCT(virtual_machine_id) FROM deployments)').each {|vm| vm.destroy }
  end

  def select_tmpl_and_flavor(tmpls)
    required_mem = tmpls.first.appliance_type.preference_memory || (tmpls.first.compute_site.public? ? 1536 : 512)
    required_cores = tmpls.first.appliance_type.preference_cpu || 1
    required_disk = tmpls.first.appliance_type.preference_disk || 0
    opt_flavors_and_tmpls_map = {}
    tmpls.each do |tmpl|
      opt_fl = (min_elements_by(tmpl.compute_site.virtual_machine_flavors.select {|f| f.memory >= required_mem and f.cpu >= required_cores and f.hdd >= required_disk}) {|f| f.hourly_cost}).sort!{ |x,y| y.memory <=> x.memory }.last
      opt_flavors_and_tmpls_map[opt_fl] = tmpl if opt_fl
    end
    globally_opt_flavor = (min_elements_by(opt_flavors_and_tmpls_map.keys){|f| f.hourly_cost}).sort{ |x,y| x.memory <=> y.memory }.last
    [opt_flavors_and_tmpls_map[globally_opt_flavor], globally_opt_flavor]
  end


end