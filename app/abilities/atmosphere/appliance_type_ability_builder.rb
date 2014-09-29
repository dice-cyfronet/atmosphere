#
# Appliance type abilities.
#
class ApplianceTypeAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can [:read, :endpoint_payload], ApplianceType, visible_to: 'all'
    can [:read, :endpoint_payload], ApplianceType, user_id: user.id
    can [:update, :destroy], ApplianceType do |at|
      pdp.can_manage?(at)
    end
  end

  def add_developer_abilities!
    can :read, ApplianceType, visible_to: 'developer'
    can :create, ApplianceType
  end

  def add_anonymous_abilities!
    can [:endpoint_payload], ApplianceType, visible_to: 'all'
  end
end
