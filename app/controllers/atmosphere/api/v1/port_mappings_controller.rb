module Api
  module V1
    class PortMappingsController < Api::ApplicationController
      load_and_authorize_resource :port_mapping
      respond_to :json

      def index
        respond_with @port_mappings.where(filter).order(:id)
      end

      def show
        respond_with @port_mapping
      end
    end
  end
end