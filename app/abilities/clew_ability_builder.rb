class ClewAbilityBuilder < AbilityBuilder

  def add_user_abilities!

    can :appliance_instances, ApplianceSet, user_id: user.id

    can :appliance_types, ApplianceType, visible_to: 'all'
    can :appliance_types, ApplianceType, user_id: user.id

  end




end
