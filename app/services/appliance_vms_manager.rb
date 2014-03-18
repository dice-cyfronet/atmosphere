class ApplianceVmsManager

  def initialize(appliance,
      updater_class=Proxy::ApplianceProxyUpdater,
      vm_creator_class=Cloud::VmCreator)
    @appliance = appliance
    @updater = updater_class.new(appliance)
    @vm_creator_class = vm_creator_class
  end

  def can_reuse_vm?
    !appliance.development? && appliance.appliance_type.shared
  end

  def reuse_vm!(vm)
    BillingService.can_afford_vm?(appliance, vm) ?
      add_vm(vm) : not_enough_funds
  end

  def spawn_vm!(tmpl, flavor, name)
    BillingService.can_afford_flavor?(appliance, flavor) ? instantiate_vm(tmpl, flavor, name) : not_enough_funds
  end

  def save
    appliance.save.tap { |saved| bill if saved }
  end

  private

  attr_reader :appliance, :updater

  def not_enough_funds
    appliance.state = :unsatisfied
    appliance.billing_state = "expired"
    appliance.state_explanation = 'Not enough funds'
  end

  def instantiate_vm(tmpl, flavor, name)
    server_id = start_vm_on_cloud(tmpl, flavor, name)
    vm = VirtualMachine.create(name: name, source_template: tmpl, state: :build, virtual_machine_flavor: flavor, appliances: [appliance], managed_by_atmosphere: true, id_at_site: server_id, compute_site: tmpl.compute_site)
    appliance_satisfied(vm)
  end

  def start_vm_on_cloud(tmpl, flavor, name)
    @vm_creator_class.new(tmpl,
        flavor: flavor, name: name,
        user_data: appliance.user_data,
        user_key: appliance.user_key
      ).spawn_vm!
  end

  def add_vm(vm)
    appliance.virtual_machines << vm
    appliance_satisfied(vm)
  end

  def appliance_satisfied(vm)
    appliance.state = :satisfied
    updater.update(new_vm: vm)
  end

  def bill
    BillingService.bill_appliance(appliance, Time.now.utc, "Optimization completed - performing billing action.", true) if appliance.state.satisfied?
  end
end