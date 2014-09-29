module Atmosphere
  class Ability
    include CanCan::Ability

    @@ability_builder_classes = [
        ::UserAbilityBuilder,
        ::ComputeSiteAbilityBuilder,
        ::ApplianceAbilityBuilder,
        ::ApplianceTypeAbilityBuilder,
        ::ApplianceSetAbilityBuilder,
        ::EndpointAbilityBuilder,
        ::OwnedPayloadAbilityBuilder,
        ::ApplianceConfigurationTemplateAbilityBuilder,
        ::ApplianceConfigurationInstanceAbilityBuilder,
        ::PortMappingTemplateAbilityBuilder,
        ::PortMappingPropertyAbilityBuilder,
        ::DevModePropertySetAbilityBuilder,
        ::VirtualMachineAbilityBuilder,
        ::VirtualMachineTemplateAbilityBuilder,
        ::HttpMappingAbilityBuilder,
        ::PortMappingAbilityBuilder,
        ::UserKeyAbilityBuilder,
        ::VirtualMachineFlavorAbilityBuilder,
        ::ClewAbilityBuilder
      ]

    def initialize(user, load_admin_abilities = true)
      @ability_builders = @@ability_builder_classes.collect do |builder_class|
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
      user ||= User.new
      apply_abilities_for! :anonymous
    end

    private

    def apply_abilities_for!(type)
      @ability_builders.each do |builder|
        builder.send("add_#{type}_abilities!")
      end
    end
  end
end
