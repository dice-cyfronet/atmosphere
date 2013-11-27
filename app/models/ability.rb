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
    can :read, ApplianceType, visible_for: 'developer'
    can :create, ApplianceType
    can :save_vm_as_tmpl, Appliance, appliance_set: {user_id: user.id, appliance_set_type: 'development'} #appl.appliance_set.user_id != current_user.id or appl.appliance_set.appliance_set_type != 'development'
    can :read, ApplianceConfigurationTemplate, appliance_type: { visible_for: 'developer' }
    can [:read, :update], DevModePropertySet, appliance: { appliance_set: { user_id: user.id } }
  end

  def initialize_normal_user_roles(user)
    can :read, ComputeSite

    ## Appliance sets
    can :create, ApplianceSet, appliance_set_type: 'portal'
    can :create, ApplianceSet, appliance_set_type: 'workflow'
    can [:read, :update, :destroy], ApplianceSet, user_id: user.id

    ## Appliances
    can [:read, :create, :destroy, :endpoints], Appliance, appliance_set: { user_id: user.id }
    can :index, ApplianceConfigurationInstance, appliances: { appliance_set: { user_id: user.id } }
    can :show, ApplianceConfigurationInstance do |conf_instance|
      ApplianceSet.joins(:appliances).where(appliances: {appliance_configuration_instance_id: conf_instance.id}, user_id: user.id).count > 0
    end

    ## Appliance types
    can [:read, :endpoint_payload], ApplianceType, visible_for: 'all'
    can [:read, :endpoint_payload], ApplianceType, user_id: user.id
    can [:update, :destroy], ApplianceType, user_id: user.id

    ## Elements of Appliance Types
    can :read, ApplianceConfigurationTemplate, appliance_type: { user_id: user.id }
    can :read, ApplianceConfigurationTemplate, appliance_type: { visible_for: 'all' }
    can [:create, :update, :destroy], ApplianceConfigurationTemplate, appliance_type: {user_id: user.id}

    can :read, PortMappingTemplate, appliance_type: { user_id: user.id }
    can :read, PortMappingTemplate, appliance_type: { visible_for: 'all' }
    can [:create, :update, :destroy], PortMappingTemplate, appliance_type: {user_id: user.id}
    can [:read, :create, :update, :destroy], PortMappingTemplate, dev_mode_property_set: { appliance: { appliance_set: { user_id: user.id } } }

    can :read, Endpoint, port_mapping_template: { appliance_type: { user_id: user.id } }
    can :read, Endpoint, port_mapping_template: { appliance_type: { visible_for: 'all' } }
    can [:create, :update, :destroy], Endpoint, port_mapping_template: { appliance_type: {user_id: user.id} }
    can [:read, :create, :update, :destroy], Endpoint, port_mapping_template: { dev_mode_property_set: { appliance: { appliance_set: { user_id: user.id } } } }

    can :read, PortMappingProperty, port_mapping_template: { appliance_type: { user_id: user.id } }
    can :read, PortMappingProperty, port_mapping_template: { appliance_type: { visible_for: 'all' } }
    can [:create, :update, :destroy], PortMappingProperty, port_mapping_template: { appliance_type: {user_id: user.id} }

    ## Virtual Machines
    can :index, VirtualMachine, appliances: { appliance_set: { user_id: user.id } }

    can :show, VirtualMachine do |vm|
      # There is a problem with hash query for getting resource with m2m relation.
      # That is why we are using block here
      ApplianceSet.with_vm(vm).where(user_id: user.id).count > 0
    end

    ## Mappings
    can :read, HttpMapping, appliance: { appliance_set: { user_id: user.id } }
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
