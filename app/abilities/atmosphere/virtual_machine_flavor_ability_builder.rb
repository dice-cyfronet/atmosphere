module Atmosphere
  class VirtualMachineFlavorAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, VirtualMachineFlavor
    end
  end
end