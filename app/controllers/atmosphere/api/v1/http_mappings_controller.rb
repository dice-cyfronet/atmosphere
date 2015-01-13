module Atmosphere
  module Api
    module V1
      class HttpMappingsController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :http_mapping,
          class: 'Atmosphere::HttpMapping'

        include Atmosphere::Api::Auditable

        respond_to :json

        def index
          respond_with HttpMappingSerializer.
                        page(params, @http_mappings).order(:id)
        end

        def show
          respond_with @http_mapping
        end

        def update
          @http_mapping.update_attributes!(update_params)
          render json: @http_mapping
        end

        private

        def update_params
          @update_params ||= params.require(:http_mapping).permit(:custom_name)
        end

        def model_class
          Atmosphere::HttpMapping
        end
      end
    end
  end
end
