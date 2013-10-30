class Ability
  include CanCan::Ability

  def initialize(user, load_admin_abilities = true)

    ### Logged in user abilities
    if user
      if user.has_role? :developer
        can :create, ApplianceSet, appliance_set_type: 'development'
      end

      ## Appliance sets
      can :create, ApplianceSet, appliance_set_type: 'portal'
      can :create, ApplianceSet, appliance_set_type: 'workflow'
      can [:read, :update, :destroy], ApplianceSet, user_id: user.id

      ## Appliances
      can [:read, :create, :destroy], Appliance, appliance_set: { user_id: user.id }

      ## Appliance types
      can [:read], ApplianceType
      can [:update, :destroy], ApplianceType, user_id: user.id

      can [:read], ApplianceConfigurationTemplate, appliance_type: {user_id: user.id }
      can [:read], ApplianceConfigurationTemplate, appliance_type: { visibility: 'published' }

      can [:create, :update, :destroy], ApplianceConfigurationTemplate, appliance_type: {user_id: user.id}

      ## Http mappings

      can [:read], HttpMapping

      ## Security proxies and policies
      can :create, owned_payloads
      can [:update, :destroy], owned_payloads do |item|
        item.users.include? user
      end

      can :manage, UserKey, user_id: user.id

      can :manage, :all if (user.has_role? :admin) && load_admin_abilities
    end

    ### Anonymous user abilities
    user ||= User.new
    can [:read, :payload], owned_payloads
  end

  private

  def owned_payloads
    [SecurityProxy, SecurityPolicy]
  end
end
