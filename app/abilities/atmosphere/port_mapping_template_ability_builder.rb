#
# Port mapping template abilities.
#
module Atmosphere
  class PortMappingTemplateAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, PortMappingTemplate, appliance_type: { user_id: user.id }

      can :read, PortMappingTemplate, appliance_type: { visible_to: 'all' }

      can [:read, :create, :update, :destroy], PortMappingTemplate,
          dev_mode_property_set: {
            appliance: { appliance_set: { user_id: user.id } }
          }

      can [:create, :update, :destroy], PortMappingTemplate do |pmt|
        pmt.appliance_type && pdp.can_manage?(pmt.appliance_type)
      end
    end
  end
end