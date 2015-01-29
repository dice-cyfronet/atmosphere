module Atmosphere
  module Api
    module V1
      class ActionsController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :action,
                                    class: 'Atmosphere::Action'

        respond_to :json

        def index
          respond_with @actions.where(filter).order(:id).uniq
        end

        def show
          respond_with @actions
        end

        private

        def model_class
          Atmosphere::Action
        end

      end
    end
  end
end