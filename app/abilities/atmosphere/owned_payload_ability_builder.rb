#
# Security proxy and policy abilities.
#
module Atmosphere
  class OwnedPayloadAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :create, owned_payloads
      can [:update, :destroy], owned_payloads do |item|
        item.users.include? user
      end
    end

    def add_anonymous_abilities!
      can [:read, :payload], owned_payloads
    end

    private

    def owned_payloads
      [SecurityProxy, SecurityPolicy]
    end
  end
end