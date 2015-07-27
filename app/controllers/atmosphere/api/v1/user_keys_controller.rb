module Atmosphere
  module Api
    module V1
      class UserKeysController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :user_key,
          class: 'Atmosphere::UserKey'

        include Atmosphere::Api::Auditable

        respond_to :json

        def index
          respond_with @user_keys.order(:name).where(filter)
        end

        def show
          respond_with @user_key
        end

        def create
          if params[:user_key] && (params[:user_key][:public_key].is_a? ActionDispatch::Http::UploadedFile)
            log_user_action 'the public user key was uploaded with a file'
            @user_key.public_key = params[:user_key][:public_key].read
          end
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

        def user_key_params
          params.require(:user_key).permit(:public_key, :name)
        end

        def model_class
          Atmosphere::UserKey
        end
      end
    end
  end
end
