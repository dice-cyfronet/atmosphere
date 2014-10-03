module Atmosphere
  module Api
    module V1
      class UsersController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :user,
          class: 'Atmosphere::User'

        respond_to :json

        def index
          respond_with @users.where(filter).order(:id)
        end

        def show
          respond_with @user
        end

        def model_class
          Atmosphere::User
        end
      end
    end
  end
end