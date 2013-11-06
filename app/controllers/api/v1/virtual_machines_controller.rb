module Api
  module V1
    class VirtualMachinesController < Api::ApplicationController
      load_and_authorize_resource :virtual_machine
      respond_to :json

      def index
        respond_with @virtual_machines.distinct
      end

      def show
        respond_with @virtual_machine
      end
    end
  end
end