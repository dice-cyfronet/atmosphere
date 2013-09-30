module Api
  module V1
    class AppliancesController < Api::ApplicationController
      load_resource :appliance_set
      before_filter :create_appliance, only: :create
      load_and_authorize_resource :appliance, through: :appliance_set
      before_filter :check_for_conflict!

      def create
        @appliance_set.transaction do
          @appliance.appliance_type = config_template.appliance_type
          @appliance.appliance_configuration_instance =create_configuration_instance
          @appliance.save!
          render json: @appliance, status: :created
        end
      end

      private

      def create_appliance
        @appliance = @appliance_set.appliances.create
      end

      def check_for_conflict!
        if @appliance_set.production? and not appliance_unique?
          raise Air::Conflict.new 'You are not able to start 2 appliances with the same type and configuration in production appliance set'
        end
      end

      def appliance_unique?
        Appliance.joins(:appliance_configuration_instance).where(appliance_configuration_instances: {payload: config_payload}, appliance_set: @appliance_set).count == 0
      end

      def create_configuration_instance
        ApplianceConfigurationInstance.create(payload: config_template.payload, appliance_configuration_template: config_template)
      end

      def config_payload
        config_template.payload
      end

      def config_template
        @config_template ||= ApplianceConfigurationTemplate.find(config_template_id)
      end

      def config_template_id
        params[:appliance][:configuration_template_id] if params[:appliance]
      end
    end
  end
end