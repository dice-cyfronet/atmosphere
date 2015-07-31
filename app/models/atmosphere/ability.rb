module Atmosphere
  class Ability
    include ::CanCan::Ability

    @@ability_builder_classes = [
      ::Atmosphere::UserAbilityBuilder,
      ::Atmosphere::TenantAbilityBuilder,
      ::Atmosphere::ApplianceAbilityBuilder,
      ::Atmosphere::ApplianceTypeAbilityBuilder,
      ::Atmosphere::ApplianceSetAbilityBuilder,
      ::Atmosphere::EndpointAbilityBuilder,
      ::Atmosphere::ApplianceConfigurationTemplateAbilityBuilder,
      ::Atmosphere::ApplianceConfigurationInstanceAbilityBuilder,
      ::Atmosphere::PortMappingTemplateAbilityBuilder,
      ::Atmosphere::PortMappingPropertyAbilityBuilder,
      ::Atmosphere::DevModePropertySetAbilityBuilder,
      ::Atmosphere::VirtualMachineAbilityBuilder,
      ::Atmosphere::VirtualMachineTemplateAbilityBuilder,
      ::Atmosphere::HttpMappingAbilityBuilder,
      ::Atmosphere::PortMappingAbilityBuilder,
      ::Atmosphere::UserKeyAbilityBuilder,
      ::Atmosphere::VirtualMachineFlavorAbilityBuilder,
      ::Atmosphere::ClewAbilityBuilder,
      ::Atmosphere::ActionAbilityBuilder
    ]

    def initialize(user, load_admin_abilities = true)
      @ability_builders = ability_builder_classes.map do |builder_class|
        builder_class.new(self, user)
      end

      ### Logged in user abilities
      if user
        if (user.has_role? :admin) && load_admin_abilities
          can :manage, :all
        else
          apply_abilities_for! :developer if user.has_role? :developer
          apply_abilities_for! :user
        end
      end

      ### Anonymous user activities
      user ||= Atmosphere::User.new
      apply_abilities_for! :anonymous
    end

    protected

    def ability_builder_classes_ext
      []
    end

    private

    def ability_builder_classes
      @@ability_builder_classes + ability_builder_classes_ext
    end

    def apply_abilities_for!(type)
      @ability_builders.each do |builder|
        builder.send("add_#{type}_abilities!")
      end
    end
  end
end
