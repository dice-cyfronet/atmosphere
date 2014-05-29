#
# Virtual machine abilities.
#
class VirtualMachineAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :index, VirtualMachine,
        appliances: { appliance_set: { user_id: user.id } }

    can :show, VirtualMachine do |vm|
      # There is a problem with hash query for getting resource
      # with m2m relation. That is why we are using block here.
      ApplianceSet.with_vm(vm).where(user_id: user.id).count > 0
    end
  end
end
