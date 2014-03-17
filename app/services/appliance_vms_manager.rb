class ApplianceVmsManager

  def initialize(appliance, updater_class=Proxy::ApplianceProxyUpdater)
    @appliance = appliance
    @updater = updater_class.new(appliance)
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
    vm = appliance.virtual_machines.create(name: name, source_template: tmpl, state: :build, virtual_machine_flavor: flavor)
    appliance_satisfied(vm)
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