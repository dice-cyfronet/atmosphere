module Api
  module V1
    class EndpointsController < Api::ApplicationController

      load_and_authorize_resource :appliance_type
      load_and_authorize_resource :port_mapping_template, through: :appliance_type
      load_and_authorize_resource :endpoint, through: :port_mapping_template
      #load_and_authorize_resource :appliance_type
      #load_and_authorize_resource :port_mapping_template, through: :appliance_type
      respond_to :json

      def index
        respond_with @endpoints
      end

      def show
        respond_with @endpoint
      end

      def create
        @endpoint.save!
        render json: @endpoint, serializer: EndpointSerializer, status: :created
      end

      def update
        update_params = endpoint_params
        @endpoint.update_attributes!(update_params)
        render json: @endpoint, serializer: EndpointSerializer
      end

      def destroy
        if @endpoint.destroy
          render json: {}
        else
          render_error @endpoint
        end
      end

      private

      def endpoint_params
        params.require(:endpoint).permit(:endpoint_type, :description, :descriptor)
      end

    end # of EndpointsController
  end # of V1
end # of Api