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
        update_params = appliance_type_params
        update_params[:author] = User.find(update_params[:author]) if update_params[:author]

        if @appliance_type.update_attributes(update_params)
          # http://stackoverflow.com/questions/18673993/ember-data-showing-field-from-belongsto-relation-after-save
          # render json: @appliance_type, serializer: ApplianceTypeSerializer
          render json: {}, status: 200
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
        params.require(:appliance_type).permit(:name, :description, :shared, :scalable, :visibility, :author)
      end
    end
  end
end