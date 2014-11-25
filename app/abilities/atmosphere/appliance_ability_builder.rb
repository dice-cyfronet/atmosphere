#
# Appliance abilities.
#
module Atmosphere
  class ApplianceAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can [:read, :update, :destroy, :endpoints, :action],
          Appliance, appliance_set: { user_id: user.id }

      can :create, Appliance do |appl|
        appl.owned_by?(user) &&
          appl.appliance_type.appropriate_for?(appl.appliance_set) &&
            can_start?(appl)
      end

      can :reboot, Appliance, appliance_set: {
        user_id: user.id, appliance_set_type: 'development'
      }
    end

    def add_developer_abilities!
      can :save_vm_as_tmpl, Appliance,
          appliance_set: { user_id: user.id, appliance_set_type: 'development' }
    end

    private

    def can_start?(appliance)
      at = appliance.appliance_type
      if appliance.development?
        pdp.can_start_in_development?(at)
      else
        pdp.can_start_in_production?(at)
      end
    end
  end
end
