module Api
  module V1
    class UsersController < Api::ApplicationController
      load_and_authorize_resource :user
      respond_to :json

      def index
        respond_with @users.where(filter).order(:id)
      end

      def show
        respond_with @user
      end
    end
  end
end