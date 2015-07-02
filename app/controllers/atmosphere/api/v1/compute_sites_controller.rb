module Atmosphere
  module Api
    module V1
      class ComputeSitesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :tenant,
                                    parent: false,
                                    class: 'Atmosphere::Tenant'

        respond_to :json

        def index
          respond_with @tenants.where(filter).order(:id),
                       root: :compute_sites
        end

        def show
          respond_with @tenant,
                       root: :compute_site
        end

        def model_class
          Atmosphere::Tenant
        end

        private

        def filter
          super.tap do |f|
            f[:tenant_type] = params[:site_type] if params[:site_type]
            f[:tenant_id] = params[:site_id] if params[:site_id]
          end
        end
      end
    end
  end
end
