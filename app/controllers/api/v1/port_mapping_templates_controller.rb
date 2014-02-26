module Api
  module V1
    class PortMappingTemplatesController < Api::ApplicationController

      before_filter :find_port_mapping_templates, only: :index
      load_and_authorize_resource :port_mapping_template, except: :index
      authorize_resource :port_mapping_template, only: :index
      before_filter :initialize_manager, only: [:create, :update, :destroy]
      respond_to :json

      def index
        respond_with @port_mapping_templates.where(filter)
      end

      def show
        respond_with @port_mapping_template
      end

      def create
        log_user_action "create new port mapping template with following params #{params}"
        @manager.save!
        render json: @manager.port_mapping_template, status: :created
        log_user_action "port mapping template created: #{@port_mapping_template.to_json}"
      end

      def update
        log_user_action "update port mapping template #{@port_mapping_template.id} with following params #{params}"
        update_params = port_mapping_template_params
        @manager.update!(update_params)
        render json: @manager.port_mapping_template
        log_user_action "port mapping template updated: #{@port_mapping_template.to_json}"
      end

      def destroy
        log_user_action "destroy port mapping template #{@port_mapping_template.id}"
        if @manager.destroy
          render json: {}
          log_user_action "port mapping template destroyed: #{@port_mapping_template.id}"
        else
          render_error @manager.port_mapping_template
        end
      end

      private

      def find_port_mapping_templates
        if params[:appliance_type_id]
          @appliance_type = ApplianceType.find(params[:appliance_type_id])
          @port_mapping_templates = PortMappingTemplate.where(appliance_type: @appliance_type)
          authorize!(:index, @appliance_type)
        else
          @dev_mode_property_set = DevModePropertySet.find(params[:dev_mode_property_set_id])
          @port_mapping_templates = PortMappingTemplate.where(dev_mode_property_set: @dev_mode_property_set)
          authorize!(:index, @dev_mode_property_set.appliance.appliance_set)
        end
      end

      def port_mapping_template_params
        params.require(:port_mapping_template).permit(
            :service_name, :target_port, :transport_protocol, :application_protocol, :appliance_type_id, :dev_mode_property_set_id)
      end

      def initialize_manager
        @manager = PmtManager.new(@port_mapping_template)
      end
    end # of PortMappingTemplatesController
  end # of V1
end # of Api