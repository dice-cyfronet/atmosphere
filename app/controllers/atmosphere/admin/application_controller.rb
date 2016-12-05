class Atmosphere::Admin::ApplicationController < Atmosphere::ApplicationController
  before_action :only_admin_allowed
  layout 'layouts/atmosphere/application'

  private

  def only_admin_allowed
    raise CanCan::AccessDenied unless current_user && current_user.admin?
  end

  def current_ability
    @current_ability ||= Atmosphere.ability_class.new(current_user, true)
  end
end