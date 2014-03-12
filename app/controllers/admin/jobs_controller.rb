class Admin::JobsController < Admin::ApplicationController
  authorize_resource :class => false

  def show
  end
end