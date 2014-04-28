#
# Port mapping property abilities.
#
class PortMappingPropertyAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :read, PortMappingProperty,
        port_mapping_template: { appliance_type: { user_id: user.id } }

    can :read, PortMappingProperty,
        port_mapping_template: { appliance_type: { visible_to: 'all' } }

    can [:create, :update, :destroy], PortMappingProperty do |pmp|
      pmt = pmp.port_mapping_template
      pmt && pmt.appliance_type && pdp.can_manage?(pmt.appliance_type)
    end
  end
end
