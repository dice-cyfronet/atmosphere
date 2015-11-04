#
# Port mapping property abilities.
#
module Atmosphere
  class PortMappingPropertyAbilityBuilder < AbilityBuilder
    def add_user_abilities!
      can :read, PortMappingProperty,
          port_mapping_template: { appliance_type: { user_id: user.id } }

      can :read, PortMappingProperty,
          port_mapping_template: { appliance_type: { visible_to: 'all' } }

      can :read, PortMappingProperty,
          port_mapping_template: {
            dev_mode_property_set: {
              appliance: { appliance_set: { user_id: user.id } }
            }
          }

      can [:create, :update, :destroy], PortMappingProperty do |pmp|
        pmt = pmp.port_mapping_template
        pmt_parent_obj = pmt.appliance_type || pmt.dev_mode_property_set
        pmt && pmt_parent_obj && pdp.can_manage?(pmt_parent_obj)
      end
    end
  end
end
