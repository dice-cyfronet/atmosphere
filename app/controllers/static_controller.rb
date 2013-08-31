class StaticController < ApplicationController
  layout 'air'
  skip_authorization_check

  def index
    authenticate_user!
    render layout: true, nothing: true
  end
end
