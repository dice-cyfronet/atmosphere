class Atmosphere::Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def vphticket
    @user = User.vph_find_or_create(oauth)
    @user.remember_me = true if params[:remember_me]
    sign_in_and_redirect(@user)
  end

  private

  def oauth
    @oauth ||= request.env['omniauth.auth']
  end
end