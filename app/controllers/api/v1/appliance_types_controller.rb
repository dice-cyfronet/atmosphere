module Api
  module V1
    class ApplianceTypesController < ApplicationController
      load_and_authorize_resource :appliance_type
      respond_to :json

      def index
        respond_with @appliance_types
      end

      def show
        respond_with @appliance_type
      end
    end
  end
end