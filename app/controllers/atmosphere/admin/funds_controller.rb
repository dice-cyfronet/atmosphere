class Atmosphere::Admin::FundsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :fund, class: 'Atmosphere::Fund'

  # GET /funds
  def index
  end

end
