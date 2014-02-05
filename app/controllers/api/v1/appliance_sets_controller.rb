module Api
  module V1
    class ApplianceSetsController < Api::ApplicationController
      before_filter :create_appliance_set, only: :create
      load_and_authorize_resource :appliance_set
      respond_to :json

      def index
        respond_with @appliance_sets.where(filter).order(:id)
      end

      def show
        respond_with @appliance_set
      end

      def create
        log_user_action "create new appliance set with following params #{params}"
        if conflicted? @appliance_set.appliance_set_type
          msg = "Unable to create two #{@appliance_set.appliance_set_type} appliance sets"
          render json: {message: msg}, status: :conflict
          log_user_action msg
        else
          @appliance_set.save!
          render json: @appliance_set, serializer: ApplianceSetSerializer, status: :created
          log_user_action "appliance set created: #{@appliance_set.to_json}"
        end
      end

      def update
        log_user_action "update appliance set #{@appliance_set.id} with following params #{params}"
        @appliance_set.update_attributes!(appliance_set_update_params)
        render json: @appliance_set, serializer: ApplianceSetSerializer
        log_user_action "appliance set updated: #{@appliance_set.to_json}"
      end

      def destroy
        log_user_action "destroy appliance set #{@appliance_set.id}"
        if @appliance_set.destroy
          render json: {}
          log_user_action "appliance set #{@appliance_set.id} destroyed"
        else
          render_error @appliance_set
        end
      end

      private
      def appliance_set_params
        params.require(:appliance_set).permit(:appliance_set_type, :name, :priority)
      end

      def appliance_set_update_params
        params.require(:appliance_set).permit(:name, :priority)
      end

      def create_appliance_set
        @appliance_set = ApplianceSet.new params[:appliance_set]
        @appliance_set.user = current_user
      end

      def conflicted?(type)
        not type.workflow? and current_user.appliance_sets.where(appliance_set_type: type).count > 0
      end

      def set_appliance_sets
        if current_user
          @appliance_sets = load_all? ? ApplianceSet.all : current_user.appliance_sets
        end
      end
    end
  end
end