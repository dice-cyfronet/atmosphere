#
# Tenant abilities.
#
module Atmosphere
  class TenantAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, Tenant, funds: { users: { id: user.id } }
    end
  end
end
