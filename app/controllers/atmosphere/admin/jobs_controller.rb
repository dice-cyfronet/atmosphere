class Atmosphere::Admin::JobsController < Atmosphere::Admin::ApplicationController
  authorize_resource :class => false

  def show
  end
end