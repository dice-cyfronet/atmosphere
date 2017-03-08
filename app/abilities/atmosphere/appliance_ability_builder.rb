#
# Appliance abilities.
#
module Atmosphere
  class ApplianceAbilityBuilder < AbilityBuilder
    include Atmosphere::ApplianceAbilityBuilderExt

    def add_user_abilities!
      can [:read, :update, :destroy, :endpoints, :action],
          Appliance, appliance_set: { user_id: user.id }

      can :create, Appliance do |appl|

        # Rails.logger.debug("CAN CREATE APPLIANCE?")
        # if appl.owned_by?(user)
        #   Rails.logger.debug("...appliance is owned by user.")
        # end
        # if appl.appliance_type.appropriate_for?(appl.appliance_set)
        #   Rails.logger.debug("...appliance is appropriate for this appliance set.")
        # end
        # if can_start?(appl)
        #   Rails.logger.debug("...user is allowed to start this appliance.")
        # end
        # if can_start_ext?(appl)
        #   Rails.logger.debug("...user is allowed to start this appliance (ext conditions verified).")
        # end

        appl.owned_by?(user) &&
          appl.appliance_type.appropriate_for?(appl.appliance_set) &&
            can_start?(appl) &&
              can_start_ext?(appl)
      end

      can :reboot, Appliance, appliance_set: {
          user_id: user.id, appliance_set_type: 'development'
      }

      can :scale, Appliance, appliance_set: {
          user_id: user.id
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
        @pdp_class.new(user).can_start_in_development?(at)
      else
        @pdp_class.new(user).can_start_in_production?(at)
      end
    end
  end
end
