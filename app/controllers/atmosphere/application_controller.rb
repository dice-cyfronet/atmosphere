class Atmosphere::ApplicationController < ApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  check_authorization unless: :devise_controller?

  helper Atmosphere::Engine.helpers

  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil?
      session[:next] = request.fullpath
      puts session[:next]
      redirect_to new_user_session_path, alert: t('devise.failure.unauthenticated')
    else
      if request.env["HTTP_REFERER"].present?
        redirect_to :back, alert: exception.message
      else
        redirect_to root_url, alert: exception.message
      end
    end
  end
end
