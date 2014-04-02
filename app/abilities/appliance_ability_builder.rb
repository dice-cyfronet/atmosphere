class ApplianceAbilityBuilder < AbilityBuilder

  def add_user_abilities!
    can [:read, :update, :destroy, :endpoints],
      ::Appliance, appliance_set: { user_id: user.id }

    can :create, ::Appliance do |appl|
      appl.appliance_set.user_id == user.id && can_start?(appl)
    end
  end

  def add_developer_abilities!
    can :save_vm_as_tmpl, Appliance,
      appliance_set: {user_id: user.id, appliance_set_type: 'development'}
  end

  private

  def can_start?(appliance)
    appliance.development? ?
      pdp.can_start_in_development?(appliance.appliance_type) :
      pdp.can_start_in_production?(appliance.appliance_type)
  end
end