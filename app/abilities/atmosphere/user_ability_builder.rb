#
# User ability
#
class UserAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :read, User
  end
end
