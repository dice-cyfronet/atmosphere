class Atmosphere::HomeController < Atmosphere::ApplicationController
  skip_authorization_check
  layout 'layouts/atmosphere/application'

  def index
    authenticate_user!
  end

end
