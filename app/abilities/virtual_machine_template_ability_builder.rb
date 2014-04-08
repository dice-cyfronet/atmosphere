class VirtualMachineTemplateAbilityBuilder < AbilityBuilder

  def add_user_abilities!
    can :read, VirtualMachineTemplate, appliance_type: { user_id: user.id  }
    can :read, VirtualMachineTemplate, appliance_type: { visible_to: 'all' }
  end

  def add_developer_abilities!
    can :read, VirtualMachineTemplate, appliance_type: { visible_to: 'developer' }
  end
end