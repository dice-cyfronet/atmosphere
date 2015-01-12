module Atmosphere
  module Api
    module V1
      class ApplianceConfigurationTemplatesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :appliance_configuration_template,
          class: 'Atmosphere::ApplianceConfigurationTemplate'

        include Atmosphere::Api::Auditable

        respond_to :json

        def index
          respond_with @appliance_configuration_templates.
                         where(filter).order(:id)
        end

        def show
          respond_with @appliance_configuration_template
        end

        def create
          @appliance_configuration_template.save!

          render json: @appliance_configuration_template,
                 status: :created
        end

        def update
          @appliance_configuration_template.
            update_attributes!(update_params)

          render json: @appliance_configuration_template
        end

        def destroy
          if @appliance_configuration_template.destroy
            render json: {}
          else
            render_error @appliance_configuration_template
          end
        end

        private

        def appliance_configuration_template_params
          params.require(:appliance_configuration_template).
            permit(:name, :payload, :appliance_type_id)
        end

        def update_params
          params.require(:appliance_configuration_template).
            permit(:name, :payload)
        end

        def model_class
          Atmosphere::ApplianceConfigurationTemplate
        end
      end
    end
  end
end
