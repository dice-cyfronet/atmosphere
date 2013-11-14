module Api
  module V1
    class AppliancesController < Api::ApplicationController
      before_filter :create_appliance, only: :create
      load_and_authorize_resource :appliance
      before_filter :check_for_conflict!, only: :create
      respond_to :json

      def index
        respond_with @appliances.where(filter).order(:id)
      end

      def show
        respond_with @appliance
      end

      def create
        log_user_action 'create new appliance'
        @appliance.transaction do
          @appliance.appliance_type = config_template.appliance_type

          raise CanCan::AccessDenied if cannot_create_appliance?

          @appliance.appliance_configuration_instance = configuration_instance
          @appliance.save!
          render json: @appliance, status: :created
          log_user_action "appliance created: #{@appliance.to_json}"
        end
      end

      def destroy
        log_user_action "destroy appliance #{@appliance.id}"
        if @appliance.destroy
          render json: {}
          log_user_action "appliance #{@appliance.id} destroyed"
        else
          render_error @appliance
        end
      end

      private

      def cannot_create_appliance?
        type = @appliance.appliance_type
        visible_for = type.visible_for

        case visible_for.to_sym
          when :owner     then @appliance.appliance_set.user != type.author
          when :developer then !@appliance.appliance_set.appliance_set_type.development?
          else false
        end
      end

      def create_appliance
        @appliance = Appliance.new(create_params)
      end

      def create_params
        params.require(:appliance).permit(:appliance_set_id)
      end

      def check_for_conflict!
        if @appliance.appliance_set.production? and not appliance_unique?
          raise Air::Conflict.new 'You are not allowed to start 2 appliances with the same type and configuration in production appliance set'
        end
      end

      def appliance_unique?
        Appliance.joins(:appliance_configuration_instance).where(appliance_configuration_instances: {payload: configuration_instance.payload}, appliance_set: @appliance.appliance_set, appliance_type: config_template.appliance_type).count == 0
      end

      def configuration_instance
        if @config_instance.blank?
          @config_instance = ApplianceConfigurationInstance.new(appliance_configuration_template: config_template)
          @config_instance.create_payload(config_template.payload, config_params)
        end
        @config_instance
      end

      def config_template
        @config_template ||= ApplianceConfigurationTemplate.find(config_template_id)
      end

      def config_template_id
        params[:appliance][:configuration_template_id]
      end

      def config_params
        params[:appliance][:params] || {}
      end

      def in_set_context?
        not params[:appliance_set_id].blank?
      end

      def load_admin_abilities?
        in_set_context? || super
      end
    end
  end
end