module Atmosphere
  module Api
    module V1
      class ComputeSitesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :compute_site,
          class: 'Atmosphere::ComputeSite'

        respond_to :json

        def index
          respond_with @compute_sites.where(filter).order(:id)
        end

        def show
          respond_with @compute_site
        end

        def model_class
          Atmosphere::ComputeSite
        end
      end
    end
  end
end