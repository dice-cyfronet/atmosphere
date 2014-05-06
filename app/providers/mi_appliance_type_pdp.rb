require 'mi_resource_access'
#
# Integration with Master Interface (MI) sharing mechanism.
# Basically user can have assigned three roles for every resource
# registered using WP4 metadata mechanism: `reader`, `editor`
# and `manager`.
#
# When `reader` role is assigned to the Appliance Type than user
# is able to start new Appliance in production mode (`portal` or
# `workflow` Appliance Set type) using this type. `editor` role
# allows to start Appliance in development mode (`development`
# Appliance Set type). `manager` role allows to start new Appliance
# in both mentioned Appliance Set types.
#
# Additionally, when Appliance is started in production mode than
# `visible_to` of Appliance Type is checked and it allows to start
# Appliances created only from Appliance Type with `visible_to` set
# to `all` or `owner`.
#
class MiApplianceTypePdp
  def initialize(current_user, resource_access_class = MiResourceAccess)
    @current_user = current_user
    @resource_access = resource_access_class.new(
                          'AtomicService',
                          ticket: current_user.mi_ticket,
                          verify: Air.config.vph.ssl_verify,
                          url: Air.config.vph.host
                        )
  end

  #
  # User is allowed to start new appliance from AT in production
  # when AT can be started in production mode and user has
  # `Reader` or `Manager` role assigned for this AT.
  #
  def can_start_in_production?(at)
    !at.development? && can_perform_as?(at, :Reader)
  end

  #
  # User is allowed to start new appliance from AT in development
  # when user has `Reader` or `Manager` role assigned for this AT.
  #
  def can_start_in_development?(at)
    can_perform_as?(at, :Editor)
  end

  #
  # User is allowed to manage AT if user has `Manager` role is
  # assigned for this AT.
  #
  def can_manage?(at)
    can_perform_as?(at, :Manager)
  end

  #
  # Filter appliance types taking into account roles from MI:
  #
  # Params:
  #  * ats - active record relation (e.g. ApplianceType.all)
  #  * role (deafult nil):
  #    - `nil` AT available in any mode (roles reader, editor or manager)
  #    - `:production` AT available in production mode for
  #      the user (roles reader or manager)
  #    - `:development` AT available in development mode for
  #      the user (roles editor or manager)
  #    - `:manager` AT available for manager (only manager role)
  #
  def filter(ats, mode = nil)
    mode_str = mode.to_s
    role = mode_role(mode_str)

    pdp_condition = visibility_for_mode(mode_str)
    pdp_condition = pdp_condition.and(mi_pdp_ids(role)) unless show_all?

    ats.where(owner_at_in_mode(mode_str).or(pdp_condition))
  end

  private

  def can_perform_as?(at, role)
    show_all? || owner?(at) || role?(at, role)
  end

  def owner?(at)
    at.author == @current_user
  end

  def role?(at, role)
    @resource_access.has_role?(at.id, role)
  end

  def availabe_resource_ids(role)
    @resource_access.availabe_resource_ids(role)
  end

  def visibility_for_mode(mode)
    if mode == 'production'
      table[:visible_to].in([:all, :owner])
    else
      table[:visible_to].in([:all, :owner, :developer])
    end
  end

  def mi_pdp_ids(role)
    table[:id].in(availabe_resource_ids(role))
  end

  def owner_at_in_mode(mode)
    owner.and(visibility_for_mode(mode))
  end

  def owner
    table[:user_id].eq(@current_user.id)
  end

  def table
    ApplianceType.arel_table
  end

  def mode_role(mode)
    case mode
    when 'manage'  then :Manager
    when 'development' then :Editor
    else :Reader
    end
  end

  def show_all?
    Air.config.skip_pdp_for_admin && admin?
  end

  def admin?
    @current_user.has_role?(:admin)
  end
end
