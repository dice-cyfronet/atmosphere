#
# User ability
#
module Atmosphere
  class UserAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, User
    end
  end
end
