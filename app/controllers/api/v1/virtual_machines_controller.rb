module Api
  module V1
    class VirtualMachinesController < Api::ApplicationController
      load_and_authorize_resource :virtual_machine
      respond_to :json

      def index
        respond_with @virtual_machines.where(filter).distinct
      end

      def show
        respond_with @virtual_machine
      end

      private

      def filter
        appliance_id = params[:appliance_id]
        appliance_id.blank? ? {} : {appliances: {id: appliance_id}}
      end
    end
  end
end