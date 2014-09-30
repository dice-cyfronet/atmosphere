module Atmosphere
  module Api
    module V1
      class PortMappingsController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :port_mapping,
          class: 'Atmosphere::PortMapping'

        respond_to :json

        def index
          respond_with @port_mappings.where(filter).order(:id)
        end

        def show
          respond_with @port_mapping
        end

        def model_class
          Atmosphere::PortMapping
        end
      end
    end
  end
end