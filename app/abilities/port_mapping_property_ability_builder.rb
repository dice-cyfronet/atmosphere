class PortMappingPropertyAbilityBuilder < AbilityBuilder

  def add_user_abilities!
    can :read, PortMappingProperty, port_mapping_template: { appliance_type: { user_id: user.id } }
    can :read, PortMappingProperty, port_mapping_template: { appliance_type: { visible_to: 'all' } }
    can [:create, :update, :destroy], PortMappingProperty, port_mapping_template: { appliance_type: {user_id: user.id} }
  end
end