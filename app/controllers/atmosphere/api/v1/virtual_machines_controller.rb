module Atmosphere
  module Api
    module V1
      class VirtualMachinesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :virtual_machine,
          class: 'Atmosphere::VirtualMachine'

        respond_to :json

        def index
          respond_with @virtual_machines.where(filter).order(:id).distinct
        end

        def show
          respond_with @virtual_machine
        end

        private

        def filter
          filter = super
          appliance_id = params[:appliance_id]

          unless appliance_id.blank?
            filter[:atmosphere_appliances] = { id: appliance_id }
          end

          if params[:flavor_id]
            filter[:virtual_machine_flavor_id] = params[:flavor_id]
          end

          filter
        end

        def model_class
          Atmosphere::VirtualMachine
        end
      end
    end
  end
end