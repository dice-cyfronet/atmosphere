class ProfilesController < ApplicationController
  authorize_resource :class => false

  layout 'profile'

  def show

  end
end
