class MiApplianceTypePdp
  def initialize(ticket, resource_access_class=MiResourceAccess)
    @resource_access = resource_access_class.new('AtomicService', ticket: ticket)
  end

  def can_start?(at)
    @resource_access.has_role?(at.id, :reader)
  end

  def can_edit?(at)
    @resource_access.has_role?(at.id, :editor)
  end

  def can_manage?(at)
    @resource_access.has_role?(at.id, :manager)
  end

  def filter(ats)
    ats.where(id: availabe_resource_ids)
  end

  private

  def availabe_resource_ids
    @resource_access.availabe_resource_ids(:reader)
  end
end