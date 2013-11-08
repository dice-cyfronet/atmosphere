class Ability
  include CanCan::Ability

  def initialize(user, load_admin_abilities = true)

    ### Logged in user abilities
    if user
      if (user.has_role? :admin) && load_admin_abilities
        can :manage, :all
      else
        initialize_developer_roles(user) if user.has_role? :developer
        initialize_normal_user_roles(user)
      end
    end

    ### Anonymous user abilities
    user ||= User.new
    can [:read, :payload], owned_payloads
  end

  private

  def initialize_developer_roles(user)
    can :create, ApplianceSet, appliance_set_type: 'development'
    can [:read], ApplianceType, visible_for: 'developer'
    can [:read], ApplianceConfigurationTemplate, appliance_type: { visible_for: 'developer' }
  end

  def initialize_normal_user_roles(user)
    can :read, ComputeSite

    ## Appliance sets
    can :create, ApplianceSet, appliance_set_type: 'portal'
    can :create, ApplianceSet, appliance_set_type: 'workflow'
    can [:read, :update, :destroy], ApplianceSet, user_id: user.id

    ## Appliances
    can [:read, :create, :destroy], Appliance, appliance_set: { user_id: user.id }

    ## Appliance types
    can [:read], ApplianceType, visible_for: 'all'
    can [:read], ApplianceType, user_id: user.id
    can [:update, :destroy], ApplianceType, user_id: user.id

    can [:read], ApplianceConfigurationTemplate, appliance_type: { user_id: user.id }
    can [:read], ApplianceConfigurationTemplate, appliance_type: { visible_for: 'all' }

    can [:create, :update, :destroy], ApplianceConfigurationTemplate, appliance_type: {user_id: user.id}

    ## Virtual Machines
    can [:index], VirtualMachine, appliances: { appliance_set: { user_id: user.id } }

    can [:show], VirtualMachine do |vm|
      # There is a problem with hash query for getting resource with m2m relation.
      # That is why we are using block here
      ApplianceSet.with_vm(vm).where(user_id: user.id).count > 0
    end

    ## Mappings
    can [:read], HttpMapping, appliance: { appliance_set: { user_id: user.id } }
    can :index, PortMapping, virtual_machine: { appliances: { appliance_set: { user_id: user.id } } }
    can :show, PortMapping do |pm|
      ApplianceSet.with_vm(pm.virtual_machine).where(user_id: user.id).count > 0
    end

    ## Security proxies and policies
    can :create, owned_payloads
    can [:update, :destroy], owned_payloads do |item|
      item.users.include? user
    end

    can :manage, UserKey, user_id: user.id
  end

  def owned_payloads
    [SecurityProxy, SecurityPolicy]
  end
end
