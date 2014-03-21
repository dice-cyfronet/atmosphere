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
    !at.development? && has_role?(at, :reader, :manager)
  end

  #
  # User is allowed to start new appliance from AT in development
  # when user has `:reader` or `:manager` role assigned for this AT.
  #
  def can_start_in_development?(at)
    has_role?(at, :editor, :manager)
  end

  #
  # User is allowed to manage AT if user has `:manager` role is
  # assigned for this AT.
  #
  def can_manage?(at)
    has_role?(at, :manager)
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
      when nil          then [:reader, :editor, :manager]
      when :production  then [:reader, :manager]
      when :development then [:editor, :manager]
      else [:manager]
    end
  end
end