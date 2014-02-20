class ApplianceVmsManager

  def initialize(appliance, updater_class=ApplianceProxyUpdater)
    @appliance = appliance
    @updater = updater_class.new(appliance)
  end

  def can_reuse_vm?
    !appliance.development? && appliance.appliance_type.shared
  end

  def add_vm(vm)
    appliance.virtual_machines << vm
    appliance.state = :satisfied

    updater.update(new_vm: vm)
  end

  private

  attr_reader :appliance, :updater
end