class StaticController < ApplicationController
  layout 'air'
  skip_authorization_check

  def index
  end
end
