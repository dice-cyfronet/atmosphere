module Atmosphere
  module Api
    module V1
      class UserKeysController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :user_key
        respond_to :json

        def index
          respond_with @user_keys.where(filter)
        end

        def show
          respond_with @user_key
        end

        def create
          log_user_action "create new user key with following params #{params}"
          if params[:user_key] && (params[:user_key][:public_key].is_a? ActionDispatch::Http::UploadedFile)
            log_user_action 'the public user key was uploaded with a file'
            @user_key.public_key = params[:user_key][:public_key].read
          end
          @user_key.user = current_user
          @user_key.save!
          render json: @user_key, status: :created
          log_user_action "user key created #{@user_key.to_json}"
        end

        def destroy
          log_user_action "destroy user key #{@user_key.id}"
          if @user_key.destroy
            render json: {}
            log_user_action "user key #{@user_key.id} destroyed"
          else
            render_error @user_key
          end
        end

        private

        def user_key_params
          params.require(:user_key).permit(:public_key, :name)
        end
      end
    end
  end
end
