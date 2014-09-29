#
# Appliance configuration template abilities.
#
module Atmosphere
  class ApplianceConfigurationTemplateAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, ApplianceConfigurationTemplate,
          appliance_type: { user_id: user.id }

      can :read, ApplianceConfigurationTemplate,
          appliance_type: { visible_to: 'all' }

      can [:create, :update, :destroy], ApplianceConfigurationTemplate do |act|
        pdp.can_manage?(act.appliance_type)
      end
    end

    def add_developer_abilities!
      can :read, ApplianceConfigurationTemplate,
          appliance_type: { visible_to: 'developer' }
    end
  end
end