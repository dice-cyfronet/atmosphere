class Ability
  include CanCan::Ability

  def initialize(user)

    ### Logged in user abilities
    if user
      if user.has_role? :developer
        can :create, ApplianceSet, appliance_set_type: 'development'
      end

      ## Appliance sets
      can :create, ApplianceSet, appliance_set_type: 'portal'
      can :create, ApplianceSet, appliance_set_type: 'workflow'
      can [:index, :show, :update, :destroy], ApplianceSet, user_id: user.id

      ## Appliance types
      can [:index, :show], ApplianceType
      can [:update, :destroy], ApplianceType, user_id: user.id

      ## Security proxies and policies
      can :new, owned_payloads
      can [:update, :destroy], owned_payloads do |item|
        item.users.include? user
      end

      can :manage, :all if user.has_role? :admin
    end

    ### Anonymous user abilities
    user ||= User.new
    can [:index, :show], owned_payloads
  end

  private

  def owned_payloads
    [SecurityProxy, SecurityPolicy]
  end
end
