class PortMappingAbilityBuilder < AbilityBuilder

  def add_user_abilities!
    can :index, PortMapping,
      virtual_machine: { appliances: { appliance_set: { user_id: user.id } } }

    can :show, PortMapping do |pm|
      ApplianceSet.with_vm(pm.virtual_machine).where(user_id: user.id).count > 0
    end
  end
end