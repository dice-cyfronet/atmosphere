module Api
  module V1

    class VirtualMachineFlavorsController < Api::ApplicationController
      load_and_authorize_resource :virtual_machine_flavor
      respond_to :json

      def index
        respond_with @virtual_machine_flavors
      end

    end

  end
end