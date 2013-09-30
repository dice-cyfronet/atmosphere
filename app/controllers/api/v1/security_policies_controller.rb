module Api
  module V1
    class SecurityPoliciesController < Api::ApplicationController
      before_filter :find_by_name, only: :payload
      load_and_authorize_resource :security_policy
      respond_to :json

      def index
        respond_with @security_policies
      end

      def show
        respond_with @security_policy
      end

      def create
        @security_policy.save!
        render json: @security_policy, serializer: SecurityPolicySerializer, status: :created
      end

      def update
        @security_policy.update_attributes!(params[:security_policy])
        render json: @security_policy, serializer: SecurityPolicySerializer
      end

      def destroy
        if @security_policy.destroy
          render json: {}
        else
          render_error
        end
      end

      def payload
        render text: @security_policy.payload
      end

      private

      def security_policy_params
        init_owners params.require(:security_policy).permit(:name, :payload, owners: [])
      end

      def init_owners(sp_params)
        sp_params[:users] = sp_params[:owners].blank? ? [current_user] : User.where(id: sp_params[:owners]) if current_user

        sp_params.delete :owners
        sp_params
      end

      def find_by_name
        @security_policy = SecurityPolicy.find_by(name: params[:name])
        raise ActiveRecord::RecordNotFound if @security_policy.blank?
        @security_policy
      end
    end
  end
end