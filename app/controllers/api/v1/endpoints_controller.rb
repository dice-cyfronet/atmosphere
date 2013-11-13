module Api
  module V1
    class EndpointsController < Api::ApplicationController

      load_and_authorize_resource :port_mapping_template, only: [:index]
      load_and_authorize_resource :endpoint
      respond_to :json

      def index
        respond_with @endpoints.where(filter)
      end

      def show
        respond_with @endpoint
      end

      def create
        log_user_action 'create new endpoint'
        @endpoint.save!
        render json: @endpoint, serializer: EndpointSerializer, status: :created
        log_user_action "endpoint created: #{@endpoint.to_json}"
      end

      def update
        log_user_action "update endpoint #{@endpoint.id}"
        @endpoint.update_attributes!(endpoint_params)
        render json: @endpoint, serializer: EndpointSerializer
        log_user_action "endpoint updated: #{@endpoint.to_json}"
      end

      def destroy
        log_user_action "destroy endpoint #{@endpoint.id}"
        if @endpoint.destroy
          render json: {}
          log_user_action "endpoint #{@endpoint.id} destroyed"
        else
          render_error @endpoint
        end
      end

      private

      def endpoint_params
        params.require(:endpoint).permit(:endpoint_type, :description, :descriptor, :port_mapping_template_id)
      end

    end # of EndpointsController
  end # of V1
end # of Api