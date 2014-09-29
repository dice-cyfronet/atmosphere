module Api
  module V1
    class DevModePropertySetsController < Api::ApplicationController
      load_and_authorize_resource :dev_mode_property_set
      respond_to :json

      def index
        respond_with @dev_mode_property_sets.where(filter).order(:id)
      end

      def show
        respond_with @dev_mode_property_set
      end

      def update
        log_user_action "update dev mode property set #{@dev_mode_property_set.id} with following params #{params}"

        render json: @dev_mode_property_set, serializer:DevModePropertySetSerializer
        log_user_action "dev mode property set #{@dev_mode_property_set.id} updated #{@dev_mode_property_set.to_json}"
      end

      private

      def dev_mode_property_set_params
        params.require(:dev_mode_property_set).permit(:name, :description, :shared, :scalable, :preference_cpu, :preference_memory, :preference_disk, :security_proxy_id)
      end
    end
  end
end