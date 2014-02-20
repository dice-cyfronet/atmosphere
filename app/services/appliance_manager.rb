class ApplianceManager
  attr_reader :appliance

  def initialize(appliance)
    @appliance = appliance
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
    appliance.save.tap { |_| bill }
  end

  private

  def not_enough_funds
    appliance.state = :unsatisfied
    appliance.billing_state = "expired"
    appliance.state_explanation = 'Not enough funds'
  end

  def instantiate_vm(tmpl, flavor, name)
    vm = VirtualMachine.create(name: name, source_template: tmpl, state: :build, virtual_machine_flavor: flavor)
    add_vm(vm)
  end

  def add_vm(vm)
    appliance.virtual_machines << vm
    appliance.state = :satisfied
  end

  def bill
    BillingService.bill_appliance(appliance, Time.now.utc, "Optimization completed - performing billing action.", true) if appliance.state.satisfied?
  end
end