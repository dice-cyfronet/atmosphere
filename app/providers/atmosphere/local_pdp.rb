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
          appliance_type: at,
          role: ['developer', 'manager']
      )
      uat.present?
    end

    def can_manage?(obj)
      uat = UserApplianceType.where(
          user: @current_user,
          appliance_type: obj,
          role: 'manager'
      )
      obj.user_id == current_user.id || uat.present?
    end

    def filter(ats, filter = nil)
      Rails.logger.debug("LOCAL PDP: running filter op with the following filter: #{filter.inspect}")
      ats.joins(:user_appliance_types).where(visibility_for_filter(filter.to_s))
    end

    private

    attr_reader :current_user

    def visibility_for_filter(filter)
      Rails.logger.debug("LOCAL PDP: Checking visibility for filter: #{filter.inspect}")
      case filter
        when 'production'
          { atmosphere_user_appliance_types: { user_id: current_user.id,
                                               role: ['reader', 'developer', 'manager'] } }
        when 'manage'
          { atmosphere_user_appliance_types: { user_id: current_user.id,
                                               role: ['developer', 'manager'] } }
        else {}
      end
    end
  end
end