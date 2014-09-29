module Api
  module V1
    class HttpMappingsController < Api::ApplicationController
      load_and_authorize_resource :http_mapping
      respond_to :json

      def index
        respond_with HttpMappingSerializer.page(params, @http_mappings).order(:id)
      end

      def show
        respond_with @http_mapping
      end

      def update
        log_user_action "Setting #{update_params[:custom_name]} custom name " +
                        " for #{@http_mapping.id} http mapping."

        @http_mapping.update_attributes!(update_params)
        render json: @http_mapping
        log_user_action "Custon name #{update_params[:custom_name]} set " +
                        "for #{@http_mapping.id} http mapping."
      end

      private

      def update_params
        @update_params ||= params.require(:http_mapping).permit(:custom_name)
      end
    end
  end
end