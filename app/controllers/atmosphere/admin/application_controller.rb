class Admin::ApplicationController < ApplicationController
  before_filter :only_admin_allowed

  private

  def only_admin_allowed
    raise CanCan::AccessDenied unless current_user && current_user.admin?
  end
end