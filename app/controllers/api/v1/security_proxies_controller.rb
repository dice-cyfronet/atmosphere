module Api
  module V1
    class SecurityProxiesController < Api::ApplicationController
      before_filter :find_by_name, only: :payload
      load_and_authorize_resource :security_proxy
      respond_to :json

      def index
        respond_with @security_proxies
      end

      def show
        respond_with @security_proxy
      end

      def create
        if @security_proxy.save
          render json: @security_proxy, serializer: SecurityProxySerializer, status: :created
        else
          render_error
        end
      end

      def update
        if @security_proxy.update_attributes(params[:security_proxy])
          render json: @security_proxy, serializer: SecurityProxySerializer
        else
          render_error
        end
      end

      def destroy
        if @security_proxy.destroy
          render json: {}
        else
          render_error
        end
      end

      def payload
        render text: @security_proxy.payload
      end

      private

      def render_error
        render json: @security_proxy.errors, status: :unprocessable_entity
      end

      def security_proxy_params
        init_owners params.require(:security_proxy).permit(:name, :payload, owners: [])
      end

      def init_owners(sp_params)
        sp_params[:users] = sp_params[:owners].blank? ? [current_user] : User.where(id: sp_params[:owners]) if current_user

        sp_params.delete :owners
        sp_params
      end

      def find_by_name
        @security_proxy = SecurityProxy.find_by(name: params[:name])
        raise ActiveRecord::RecordNotFound if @security_proxy.blank?
        @security_proxy
      end
    end
  end
end