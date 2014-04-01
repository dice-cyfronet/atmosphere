class EndpointAbilityBuilder < AbilityBuilder

  def add_user_abilities!
    can [:read, :descriptor], Endpoint, port_mapping_template: { appliance_type: { user_id: user.id } }
    can :read, Endpoint, port_mapping_template: { appliance_type: { visible_to: 'all' } }
    can [:read, :create, :update, :destroy], Endpoint, port_mapping_template: { dev_mode_property_set: { appliance: { appliance_set: { user_id: user.id } } } }
    can [:create, :update, :destroy], Endpoint do |endpoint|
      pmt = endpoint.port_mapping_template
      pmt && pmt.appliance_type && pdp.can_manage?(pmt.appliance_type)
    end
  end

  def add_anonymous_abilities!
    can :descriptor, Endpoint, port_mapping_template: { appliance_type: { visible_to: 'all' } }
  end
end