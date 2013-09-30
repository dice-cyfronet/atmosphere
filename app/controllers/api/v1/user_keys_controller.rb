module Api
  module V1
    class UserKeysController < Api::ApplicationController
      before_action :set_user_key, only: [:show, :edit, :update, :destroy]
      before_filter :set_user_keys, only: :index
      load_and_authorize_resource :user_key
      respond_to :json

      # GET /user_keys
      def index
        respond_with @user_keys
      end

      # GET /user_keys/1
      def show
        respond_with @user_key
      end

      # POST /user_keys
      def create
        @user_key = UserKey.new(user_key_params)
        @user_key.user = current_user
        @user_key.save!
        render json: @user_key, status: :created
      end

      # DELETE /user_keys/1
      def destroy
        if @user_key.destroy
          render json: {}
        else
          render_error @user_key
        end
      end

      private
        # Use callbacks to share common setup or constraints between actions.
        def set_user_key
          @user_key = UserKey.find(params[:id])
        end

        def set_user_keys
          if current_user
            @user_keys = (current_user.has_role? :admin) ? UserKey.all : current_user.user_keys
          end
        end

        # Only allow a trusted parameter "white list" through.
        def user_key_params
          params.require([:public_key, :name])
        end
    end
  end
end
