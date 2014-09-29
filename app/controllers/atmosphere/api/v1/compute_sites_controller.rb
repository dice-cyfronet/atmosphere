module Api
  module V1
    class ComputeSitesController < Api::ApplicationController
      load_and_authorize_resource :compute_site
      respond_to :json

      def index
        respond_with @compute_sites.where(filter).order(:id)
      end

      def show
        respond_with @compute_site
      end
    end
  end
end