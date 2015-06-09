module Atmosphere
  class ApplianceCreator
    def initialize(params, delegated_auth)
      @params = params
      @delegated_auth = delegated_auth
    end

    def build
      pprovider = ApplianceParams.
                  new(@params, allowed_params_ext, @delegated_auth)

      Appliance.new(pprovider.create_params).tap do |appliance|
        if pprovider.dev_mode_params
          appliance.create_dev_mode_property_set(pprovider.dev_mode_params)
        end
        appliance.appliance_configuration_instance =
          ApplianceConfigurationInstance.
          get(pprovider.config_template, pprovider.config_params)
      end
    end

    private

    include Atmosphere::ApplianceCreatorExt
  end
end
