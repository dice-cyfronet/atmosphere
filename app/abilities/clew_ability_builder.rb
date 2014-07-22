class ClewAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :appliances, ApplianceSet, user_id: user.id
  end
end
