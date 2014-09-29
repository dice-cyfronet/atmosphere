#
# User key ability.
#
class UserKeyAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :manage, UserKey, user_id: user.id
  end
end
