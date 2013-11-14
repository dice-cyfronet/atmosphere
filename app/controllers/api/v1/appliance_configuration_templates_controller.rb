module Api
  module V1
    class ApplianceConfigurationTemplatesController < Api::ApplicationController
      load_and_authorize_resource :appliance_configuration_template
      respond_to :json

      def index
        respond_with @appliance_configuration_templates.where(filter).order(:id)
      end

      def show
        respond_with @appliance_configuration_template
      end

      def create
        log_user_action 'create new appliance configuration template'
        @appliance_configuration_template.save!
        render json: @appliance_configuration_template, status: :created
        log_user_action "appliance configuration template created: #{@appliance_configuration_template.to_json}"
      end

      def update
        log_user_action 'update appliance configuration template'
        @appliance_configuration_template.update_attributes!(update_params)
        render json: @appliance_configuration_template
        log_user_action "appliance configuration template updated: #{@appliance_configuration_template.to_json}"
      end

      def destroy
        log_user_action "destroy appliance configuration template #{@appliance_configuration_template.id}"
        if @appliance_configuration_template.destroy
          render json: {}
          log_user_action "appliance configuration template #{@appliance_configuration_template.id} destroyed"
        else
          render_error @appliance_configuration_template
        end
      end

      private

      def appliance_configuration_template_params
        params.require(:appliance_configuration_template).permit(:name, :payload, :appliance_type_id)
      end

      def update_params
        params.require(:appliance_configuration_template).permit(:name, :payload)
      end
    end
  end
end