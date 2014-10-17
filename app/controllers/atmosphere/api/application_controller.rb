module Atmosphere
  module Api
    class ApplicationController < ::ApplicationController
      protect_from_forgery with: :null_session

      check_authorization

      include CancanStrongParams
      include Filterable

      rescue_from CanCan::AccessDenied do |exception|
        if current_user.nil?
          render_json_error('401 Unauthorized', status: :unauthorized)
        else
          render_json_error('403 Forbidden', status: :forbidden)
        end
      end

      rescue_from ActiveRecord::RecordNotFound do |exception|
        render_json_error('Record not found', status: :not_found)
      end

      rescue_from ActionController::ParameterMissing, Atmosphere::InvalidParameterFormat do |exception|
        render_json_error(exception.to_s, status: :unprocessable_entity)
      end

      rescue_from Atmosphere::Conflict do |exception|
        log_user_action "record conflict #{exception}"
        render_json_error(exception.to_s, status: :conflict, type: :conflict)
      end

      rescue_from ActiveRecord::RecordInvalid do |exception|
        render_error exception.record
      end

      protected

      def render_error(model_obj)
        log_user_action("record invalid #{model_obj.errors.to_json}")
        render_json_error('Object is invalid',
          status: :unprocessable_entity,
          type: :record_invalid,
          details: model_obj.errors
        )
      end

      def render_json_error(msg, options={})
        error_json = {
          message: msg,
          type: options[:type] || :general
        }
        error_json[:details] = options[:details] if options[:details]

        render(
          json: error_json,
          status: options[:status] || :bad_request
        )
      end

      def load_all?
        is_admin? and params['all']
      end

      def is_admin?
        current_user and current_user.has_role? :admin
      end

      def to_boolean(s)
        !!(s =~ /^(true|yes|1)$/i)
      end

      private

      def log_user_action msg
        Atmosphere.action_logger.info "[#{current_user.login}] #{msg}"
      end

      def current_ability
        @current_ability ||= ::Ability.new(current_user, load_admin_abilities?)
      end

      def load_admin_abilities?
        params[:action] != 'index' or to_boolean(params[:all])
      end
    end
  end
end