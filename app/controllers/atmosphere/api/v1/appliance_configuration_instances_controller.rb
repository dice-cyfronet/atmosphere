
module Api
  module V1
    class ApplianceConfigurationInstancesController < Api::ApplicationController
      load_and_authorize_resource :appliance_configuration_instance
      respond_to :json

      def index
        respond_with @appliance_configuration_instances.where(filter).order(:id).uniq
      end

      def show
        respond_with @appliance_configuration_instance
      end

      private

      def filter
        filter = super
        appliance_id = params[:appliance_id]
        filter[:appliances] = {id: appliance_id} unless appliance_id.blank?

        filter
      end
    end
  end
end