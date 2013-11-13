module Api
  module V1
    class HttpMappingsController < Api::ApplicationController
      load_and_authorize_resource :http_mapping
      respond_to :json

      def index
        respond_with HttpMappingSerializer.page(params, @http_mappings)
      end

      def show
        respond_with @http_mapping
      end

    end
  end
end