#
# Tenant abilities.
#
module Atmosphere
  class TenantAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, Tenant
    end
  end
end
