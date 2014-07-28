class ClewAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :appliance_instances, ApplianceSet, user_id: user.id
  end
end
