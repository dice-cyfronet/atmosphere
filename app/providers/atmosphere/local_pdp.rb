#
# Local PDP with basic service sharing functionality.
# Does not require external services to operate.
#
module Atmosphere
  class LocalPdp
    def initialize(current_user)
      @current_user = current_user
    end

    def can_start_in_production?(at)
      Rails.logger.debug("can_start_in_production: using local PDP")
      uat = UserApplianceType.where(
        user: @current_user,
        appliance_type: at
      )
      uat.present?
    end

    def can_start_in_development?(at)
      Rails.logger.debug("can_start_in_development: using local PDP")
      uat = UserApplianceType.where(
          user: @current_user,
          appliance_type: at
      )
      uat.present? and ['developer', 'manager'].include? uat.first.role
    end

    def can_manage?(obj)
      uat = UserApplianceType.where(
          user: @current_user,
          appliance_type: obj,
          role: 'manager'
      )
      obj.user_id == current_user.id or uat.present?
    end

    def filter(ats, filter = nil)
      ats.where(visibility_for_filter(filter.to_s))
    end

    private

    attr_reader :current_user

    def visibility_for_filter(filter)
      case filter
      when 'production'  then { visible_to: [:all, :owner] }
      when 'manage'      then { user_id: current_user.id }
      else {}
      end
    end
  end
end