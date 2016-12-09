module Atmosphere
  module Api
    module V1
      class ApplianceConfigurationInstancesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :appliance_configuration_instance,
          class: 'Atmosphere::ApplianceConfigurationInstance'

        respond_to :json

        def index
          respond_with @appliance_configuration_instances.where(filter).order(:id).distinct
        end

        def show
          respond_with @appliance_configuration_instance
        end

        private

        def filter
          filter = super
          appliance_id = params[:appliance_id]
          filter[:atmosphere_appliances] = {id: appliance_id} unless appliance_id.blank?

          filter
        end

        def model_class
          Atmosphere::ApplianceConfigurationInstance
        end
      end
    end
  end
end