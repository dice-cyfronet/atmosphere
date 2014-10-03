class Atmosphere::ProfilesController < Atmosphere::ApplicationController
  skip_authorization_check
  before_filter :authenticate_user!

  layout 'layouts/atmosphere/profile'

  def show
  end

  def update
    if current_user.update_attributes(user_params)
      flash[:notice] = I18n.t('profiles.updated')
    end

    render 'show'
  end

  def update_password
    if current_user.update_attributes(password_params)
      flash[:notice] = I18n.t('profiles.password_changed')
      redirect_to new_user_session_path
    else
      render 'show'
    end
  end

   def reset_private_token
    if current_user.reset_authentication_token!
      flash[:notice] = I18n.t('profiles.token_updated')
    end

    redirect_to profile_path
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def user_params
    (current_user.has_role? :admin) ? params.require(:user).permit(:full_name, :login, :email) : params.require(:user).permit(:full_name, :email)
  end

end
