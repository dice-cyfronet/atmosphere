module Api
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session

    check_authorization

    include CancanStrongParams
    include Filterable

    rescue_from CanCan::AccessDenied do |exception|
      if current_user.nil?
        render json: {message: '401 Unauthorized'}, status: :unauthorized
      else
        render json: {message: '403 Forbidden'}, status: :forbidden
      end
    end

    rescue_from ActiveRecord::RecordNotFound do |exception|
      render json: {message: 'Record not found'}, status: :not_found
    end

    rescue_from ActionController::ParameterMissing, Air::InvalidParameterFormat do |exception|
      render json: {message: exception.to_s}, status: :unprocessable_entity
    end

    rescue_from Air::Conflict do |exception|
      log_user_action "record conflict #{exception}"
      render json: {message: exception}, status: :conflict
    end

    rescue_from ActiveRecord::RecordInvalid do |exception|
      render_error exception.record
    end

    protected
    def render_error(model_obj)
      log_user_action "record invalid #{model_obj.errors.to_json}"
      render json: model_obj.errors, status: :unprocessable_entity
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
      Air.action_logger.info "[#{current_user.login}] #{msg}"
    end

    def current_ability
      @current_ability ||= Ability.new(current_user, load_admin_abilities?)
    end

    def load_admin_abilities?
      params[:action] != 'index' or to_boolean(params[:all])
    end
  end
end