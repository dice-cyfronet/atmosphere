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
  def initialize(ticket, resource_access_class=MiResourceAccess)
    @resource_access = resource_access_class.new(
                          'AtomicService',
                          ticket: ticket,
                          verify: Air.config.vph.ssl_verify,
                          url: Air.config.vph.host,
                        )
  end

  #
  # User is allowed to start new appliance from AT in production
  # when AT can be started in production mode and user has
  # `Reader` or `Manager` role assigned for this AT.
  #
  def can_start_in_production?(at)
    !at.development? && has_role?(at, :Reader)
  end

  #
  # User is allowed to start new appliance from AT in development
  # when user has `Reader` or `Manager` role assigned for this AT.
  #
  def can_start_in_development?(at)
    has_role?(at, :Editor)
  end

  #
  # User is allowed to manage AT if user has `Manager` role is
  # assigned for this AT.
  #
  def can_manage?(at)
    has_role?(at, :Manager)
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
  def filter(ats, filter=nil)
    filter_str = filter.to_s
    role = filter_role(filter_str)

    where_condition = visibility_for_filter(filter_str)
    where_condition[:id] = availabe_resource_ids(role)

    ats.where(where_condition)
  end

  private

  def has_role?(at, *roles)
    roles.detect { |role|  @resource_access.has_role?(at.id, role) }
  end

  def availabe_resource_ids(role)
    @resource_access.availabe_resource_ids(role)
  end

  def visibility_for_filter(filter)
    filter == 'production' ? {visible_to: [:all, :owner]} : {}
  end

  def filter_role(filter)
    case filter
      when 'manage'  then :Manager
      when 'development' then :Editor
      else :Reader
    end
  end
end