class Atmosphere::Admin::ApplicationController < Atmosphere::ApplicationController
  before_filter :only_admin_allowed
  layout 'layouts/atmosphere/application'

  private

  def only_admin_allowed
    raise CanCan::AccessDenied unless current_user && current_user.admin?
  end
end