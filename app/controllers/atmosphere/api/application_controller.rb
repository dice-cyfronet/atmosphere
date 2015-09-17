require 'atmosphere/json_error_handler'

module Atmosphere
  module Api
    class ApplicationController < ::ApplicationController
      include Atmosphere::JsonErrorHandler

      protect_from_forgery with: :null_session, if: :token_request?
      protect_from_forgery with: :exception, unless: :token_request?

      check_authorization

      include Atmosphere::Api::ApplicationControllerExt
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

      def log_user_action(msg)
        Atmosphere.action_logger.info "[#{current_user.login}] #{msg}"
      end

      def current_ability
        @current_ability ||= Atmosphere.ability_class.
                             new(current_user, load_admin_abilities?)
      end

      def load_admin_abilities?
        params[:action] != 'index' || to_boolean(params[:all])
      end
    end
  end
end
