module Api
  module V1
    class HttpMappingsController < Api::ApplicationController
      load_and_authorize_resource :http_mapping
      before_filter :find_by_appliance_id, only: :index
      respond_to :json

      def index
        @http_mappings.where
        respond_with @http_mappings
      end

      def show
        respond_with @http_mapping
      end

      def find_by_appliance_id
        unless params[:appliance_id].blank?
          @http_mappings = @http_mappings.where appliance_id: params[:appliance_id]
        end
      end

    end
  end
end