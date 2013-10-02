module Api
  module V1
    class UserKeysController < Api::ApplicationController
      before_filter :set_user_keys, only: :index
      load_and_authorize_resource :user_key
      respond_to :json

      def index
        respond_with @user_keys
      end

      def show
        respond_with @user_key
      end

      def create
        @user_key.user = current_user
        @user_key.save!
        render json: @user_key, status: :created
      end

      def destroy
        if @user_key.destroy
          render json: {}
        else
          render_error @user_key
        end
      end

      private

      def set_user_keys
        if current_user
          @user_keys = load_all? ? UserKey.all : current_user.user_keys
        end
      end

      def user_key_params
        params.require(:user_key).permit(:public_key, :name)
      end
    end
  end
end
