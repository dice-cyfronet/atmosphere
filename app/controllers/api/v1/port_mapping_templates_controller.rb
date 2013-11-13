module Api
  module V1
    class PortMappingTemplatesController < Api::ApplicationController

      #load_resource :appliance_type
      load_and_authorize_resource :appliance_type
      load_and_authorize_resource :port_mapping_template, through: :appliance_type
      #load_and_authorize_resource :port_mapping_template
      #load_resource :port_mapping_template, through: :appliance_type
      respond_to :json

      def index
        respond_with @port_mapping_templates
      end

      def show
        respond_with @port_mapping_template
      end

      def create
        @port_mapping_template.save!
        render json: @port_mapping_template, serializer: PortMappingTemplateSerializer, status: :created
      end

      def update
        update_params = port_mapping_template_params
        @port_mapping_template.update_attributes!(update_params)
        render json: @port_mapping_template, serializer: PortMappingTemplateSerializer
      end

      def destroy
        if @port_mapping_template.destroy
          render json: {}
        else
          render_error @port_mapping_template
        end
      end

      private

      def port_mapping_template_params
        params.require(:port_mapping_template).permit(
            :service_name, :target_port, :transport_protocol, :application_protocol)
      end

    end # of PortMappingTemplatesController
  end # of V1
end # of Api