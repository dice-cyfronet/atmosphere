module Atmosphere
  module Api
    module V1
      class TenantsController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :tenant,
          class: 'Atmosphere::Tenant'

        respond_to :json

        def index
          respond_with @tenants.where(filter).order(:id)
        end

        def show
          respond_with @tenant
        end

        def model_class
          Atmosphere::Tenant
        end
      end
    end
  end
end