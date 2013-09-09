module Api
  module V1
    class ApplianceSetsController < Api::ApplicationController
      before_filter :create_appliance_set, only: :create
      before_filter :set_appliance_sets, only: :index
      load_and_authorize_resource :appliance_set
      respond_to :json

      def index
        respond_with @appliance_sets
      end

      def show
        respond_with @appliance_set
      end

      def create
        if conflicted? @appliance_set.appliance_set_type
          render json: {message: "Unable to create two #{@appliance_set.appliance_set_type} appliance sets"}, status: :conflict
        else
          if @appliance_set.save
            render json: @appliance_set, serializer: ApplianceSetSerializer, status: :created
          else
            render_error
          end
        end
      end

      def update
        if @appliance_set.update_attributes(appliance_set_update_params)
          render json: @appliance_set, serializer: ApplianceSetSerializer
        else
          render_error
        end
      end

      def destroy
        if @appliance_set.destroy
          render json: {}
        else
          render_error
        end
      end

      private

      def render_error
        render json: @appliance_set.errors, status: :unprocessable_entity
      end

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
          @appliance_sets = (current_user.has_role? :admin) ? ApplianceSet.all : current_user.appliance_sets
        end
      end
    end
  end
end