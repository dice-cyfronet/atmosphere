#
# Appliance abilities.
#
module Atmosphere
  class ActionAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, Action, appliance: { appliance_set: { user_id: user.id } }
    end
  end
end
