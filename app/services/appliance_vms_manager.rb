class ApplianceVmsManager
  attr_reader :appliance

  def initialize(appliance)
    @appliance = appliance
  end

  def can_reuse_vm?
    !appliance.development? && appliance.appliance_type.shared
  end

  def add_vm(vm)
    appliance.virtual_machines << vm
    appliance.state = :satisfied
  end
end