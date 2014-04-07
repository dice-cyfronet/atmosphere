class ApplianceSetAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :create, ApplianceSet, appliance_set_type: 'portal'
    can :create, ApplianceSet, appliance_set_type: 'workflow'
    can [:read, :update, :destroy], ApplianceSet, user_id: user.id
  end

  def add_developer_abilities!
    can :create, ApplianceSet, appliance_set_type: 'development'
  end
end