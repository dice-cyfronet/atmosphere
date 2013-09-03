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

      def create
        if @appliance_type.save
          render json: @appliance_type, serializer: ApplianceTypeSerializer, status: :created
        else
          render_error
        end
      end

      def update
        if @appliance_type.update_attributes(appliance_type_params)
          render json: @appliance_type, serializer: ApplianceTypeSerializer
        else
          render_error
        end
      end

      def destroy
        if @appliance_type.destroy
          render json: {}
        else
          render_error
        end
      end

      private

      def render_error
        render json: @appliance_type.errors, status: :unprocessable_entity
      end

      def appliance_type_params
        params.require(:appliance_type).permit(:name, :description, :shared, :scalable, :visibility)
      end
    end
  end
end