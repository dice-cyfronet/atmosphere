module Api
  module V1
    class PortMappingTemplatesController < Api::ApplicationController

      load_and_authorize_resource :appliance_type, only: [:index]
      load_and_authorize_resource :port_mapping_template#, through: :appliance_type
      respond_to :json

      def index
        respond_with @port_mapping_templates.where(filter)
      end

      def show
        respond_with @port_mapping_template
      end

      def create
        log_user_action 'create new port mapping template'
        @port_mapping_template.save!
        render json: @port_mapping_template, serializer: PortMappingTemplateSerializer, status: :created
        log_user_action "port mapping template created: #{@port_mapping_template.to_json}"
      end

      def update
        log_user_action "update port mapping template #{@port_mapping_template.id}"
        update_params = port_mapping_template_params
        @port_mapping_template.update_attributes!(update_params)
        render json: @port_mapping_template, serializer: PortMappingTemplateSerializer
        log_user_action "port mapping template updated: #{@port_mapping_template.to_json}"
      end

      def destroy
        log_user_action "destroy port mapping template #{@port_mapping_template.id}"
        if @port_mapping_template.destroy
          render json: {}
          log_user_action "port mapping template destroyed: #{@port_mapping_template.id}"
        else
          render_error @port_mapping_template
        end
      end

      private

      def port_mapping_template_params
        params.require(:port_mapping_template).permit(
            :service_name, :target_port, :transport_protocol, :application_protocol, :appliance_type_id)
      end

    end # of PortMappingTemplatesController
  end # of V1
end # of Api