class NullPdp
  def initialize(ticket)

  end

  def can_start_in_production?(at)
    true
  end

  def can_start_in_development?(at)
    true
  end

  def can_manage?(at)
    true
  end

  def filter(ats, filter=nil)
    ats.where(visibility_for_filter(filter.to_s))
  end

  private

  def visibility_for_filter(filter)
    filter == 'production' ? {visible_to: [:all, :owner]} : {}
  end
end