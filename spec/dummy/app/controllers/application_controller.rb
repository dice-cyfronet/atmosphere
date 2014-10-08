class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper Atmosphere::Engine.helpers

  def current_user
    login = params[:my_login]
    (login && Atmosphere::User.find_by(login: login)) || super
  end
end
