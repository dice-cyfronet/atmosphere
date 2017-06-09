require 'atmosphere/json_error_handler'

module Atmosphere
  module Api
    class ApplicationController < ::ApplicationController
      include Atmosphere::Api::ApplicationControllerExt
      include Atmosphere::JsonErrorHandler

      before_action :set_raven_context, if: :sentry_enabled?

      protect_from_forgery with: :null_session, if: :token_request?
      protect_from_forgery with: :exception, unless: :token_request?

      check_authorization

      include Filterable

      rescue_from CanCan::AccessDenied do
        if current_user.nil?
          render_json_error(I18n.t('errors.unauthorized'),
                            status: :unauthorized)
        else
          render_json_error(I18n.t('errors.forbidden'),
                            status: :forbidden)
        end
      end

      rescue_from ActiveRecord::RecordNotFound  do
        render_json_error('Record not found', status: :not_found)
      end

      rescue_from ActionController::ParameterMissing,
                  Atmosphere::InvalidParameterFormat do |exception|
        render_json_error(exception.to_s, status: :unprocessable_entity)
      end

      rescue_from Atmosphere::Conflict do |exception|
        log_user_action "record conflict #{exception}"
        render_json_error(exception.to_s, status: :conflict, type: :conflict)
      end

      rescue_from ActiveRecord::RecordInvalid do |exception|
        render_error exception.record
      end

      rescue_from Atmosphere::BillingException do |exception|
        render_json_error(exception.to_s,
                          status: :payment_required, type: :billing)
      end

      rescue_from Atmosphere::NotAdmin do
        render_json_error('Must be admin to use sudo',
                          status: 403, type: :sudo)
      end

      rescue_from Atmosphere::NoUser do
        render_json_error('User you want to sudo does not exist',
                          status: 404, type: :sudo)
      end

      def current_user
        @current_user ||= begin
          cu = super
          sudo_as = params[:sudo] || request.headers['HTTP-SUDO']
          if sudo_as
            raise Atmosphere::NotAdmin unless cu.admin?
            user = Atmosphere::User.find_by(login: sudo_as)
            raise Atmosphere::NoUser unless user

            user
          else
            cu
          end
        end
      end

      def pdp_class
        Atmosphere.at_pdp(current_user).class
      end

      protected

      def render_error(model_obj)
        render_json_error('Object is invalid',
                          status: :unprocessable_entity,
                          type: :record_invalid,
                          details: model_obj.errors)
      end

      def load_all?
        admin? && params['all']
      end

      def admin?
        current_user && current_user.has_role?(:admin)
      end

      def to_boolean(s)
        s =~ /^(true|yes|1)$/i
      end

      private

      def set_raven_context
        if current_user
          Raven.user_context(id: current_user.id,
                             email: current_user.email,
                             username: current_user.full_name)
        end
        Raven.extra_context(params: params.to_h, url: request.url)
      end

      def sentry_enabled?
        Rails.env.production?
      end

      def log_user_action(msg)
        Atmosphere.action_logger.info "[#{current_user.login}] #{msg}"
      end

      def current_ability
        @current_ability ||= Atmosphere.ability_class.
                             new(current_user, load_admin_abilities?, pdp_class)
      end

      def load_admin_abilities?
        params[:action] != 'index' || to_boolean(params[:all])
      end

    end
  end
end
