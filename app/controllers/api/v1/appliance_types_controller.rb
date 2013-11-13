module Api
  module V1
    class ApplianceTypesController < Api::ApplicationController
      load_and_authorize_resource :appliance_type
      respond_to :json

      def index
        respond_with @appliance_types.where(filter)
      end

      def show
        respond_with @appliance_type
      end

      def create
        log_user_action 'create new appliance type'
        @appliance_type.save!
        render json: @appliance_type, serializer: ApplianceTypeSerializer, status: :created
        log_user_action "appliance type created: #{@appliance_type.to_json}"
      end

      def update
        log_user_action "update appliance type #{@appliance_type.id}"
        update_params = appliance_type_params
        update_params[:author] = User.find(update_params[:author]) if update_params[:author]
        update_params[:security_proxy] = SecurityProxy.find(update_params[:security_proxy]) if update_params[:security_proxy]

        @appliance_type.update_attributes!(update_params)
        render json: @appliance_type, serializer: ApplianceTypeSerializer
        log_user_action "appliance type updated: #{@appliance_type.to_json}"
      end

      def destroy
        log_user_action "destroy appliance type #{@appliance_type.id}"
        if @appliance_type.destroy
          render json: {}
          log_user_action "appliance type #{@appliance_type.id} destroyed"
        else
          render_error @appliance_type
        end
      end

      private

      def appliance_type_params
        params.require(:appliance_type).permit(:name, :description, :shared, :scalable, :visible_for, :author, :preference_cpu, :preference_memory, :preference_disk, :security_proxy)
      end
    end
  end
end