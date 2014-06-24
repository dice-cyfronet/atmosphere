#
# Appliance abilities.
#
class ApplianceAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can [:read, :update, :destroy, :endpoints],
        ::Appliance, appliance_set: { user_id: user.id }

    can :create, ::Appliance do |appl|
      appl.appliance_set.user_id == user.id && can_start?(appl)
    end

    can :reboot, ::Appliance, appliance_set: {
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
