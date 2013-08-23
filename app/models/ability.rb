class Ability
  include CanCan::Ability

  def initialize(user)

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
      can [:update], ApplianceType, user_id: user.id

      can :manage, :all if user.has_role? :admin
    end
  end
end
