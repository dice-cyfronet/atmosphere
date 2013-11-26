module Api
  module V1
    class PortMappingPropertiesController < Api::ApplicationController

      load_and_authorize_resource :port_mapping_template, only: [:index]
      load_and_authorize_resource :port_mapping_property
      respond_to :json

      def index
        respond_with @port_mapping_properties.where(filter)
      end

      def show
        respond_with @port_mapping_property
      end

      def create
        log_user_action 'create new port mapping property'
        @port_mapping_property.save!
        render json: @port_mapping_property, serializer: PortMappingPropertySerializer, status: :created
        log_user_action "port mapping property created: #{@port_mapping_property.to_json}"
      end

      def update
        log_user_action "update port mapping property #{@port_mapping_property.id}"
        @port_mapping_property.update_attributes!(port_mapping_property_params)
        render json: @port_mapping_property, serializer: PortMappingPropertySerializer
        log_user_action "port mapping property updated: #{@port_mapping_property.to_json}"
      end

      def destroy
        log_user_action "destroy port mapping property #{@port_mapping_property.id}"
        if @port_mapping_property.destroy
          render json: {}
          log_user_action "port mapping property #{@port_mapping_property.id} destroyed"
        else
          render_error @port_mapping_property
        end
      end

      private

      def port_mapping_property_params
        params.require(:port_mapping_property).permit(:key, :value, :compute_site_id, :port_mapping_template_id)
      end

    end # of PortMappingPropertiesController
  end # of V1
end # of Api