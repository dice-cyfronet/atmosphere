class HomeController < ApplicationController
  skip_authorization_check

  def index
    authenticate_user!
  end

end
