class ApplianceConfigurationInstanceAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :index, ApplianceConfigurationInstance,
      appliances: { appliance_set: { user_id: user.id } }

    can :show, ApplianceConfigurationInstance do |conf_instance|
      ApplianceSet.joins(:appliances).where(
          appliances: {appliance_configuration_instance_id: conf_instance.id},
          user_id: user.id
        ).count > 0
    end
  end
end