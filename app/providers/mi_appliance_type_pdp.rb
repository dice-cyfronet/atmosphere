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
    @resource_access = resource_access_class.new('AtomicService', ticket: ticket)
  end

  #
  # User is allowed to start new appliance from AT in production
  # when AT can be started in production mode and user has
  # `:reader` or `:manager` role assigned for this AT.
  #
  def can_start_in_production?(at)
    !at.development? && has_role?(at, :Reader, :Manager)
  end

  #
  # User is allowed to start new appliance from AT in development
  # when user has `:reader` or `:manager` role assigned for this AT.
  #
  def can_start_in_development?(at)
    has_role?(at, :Editor, :Manager)
  end

  #
  # User is allowed to manage AT if user has `:manager` role is
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
    roles = filter_roles(filter)

    where_condition = filter == :production ? {visible_to: :all} : {}
    where_condition[:id] = availabe_resource_ids(roles)

    ats.where(where_condition)
  end

  private

  def has_role?(at, *roles)
    roles.detect { |role|  @resource_access.has_role?(at.id, role) }
  end

  def availabe_resource_ids(roles)
    roles.inject(Set.new) do |ids, role|
      role_ids = @resource_access.availabe_resource_ids(role)
      ids.merge(role_ids)
    end.to_a
  end

  def filter_roles(filter)
    case filter
      when nil          then [:Reader, :Editor, :Manager]
      when :production  then [:Reader, :Manager]
      when :development then [:Editor, :Manager]
      else [:Manager]
    end
  end
end