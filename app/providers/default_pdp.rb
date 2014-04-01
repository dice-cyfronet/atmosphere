class DefaultPdp
  def initialize(current_user)
    @current_user = current_user
  end

  def can_start_in_production?(at)
    true
  end

  def can_start_in_development?(at)
    true
  end

  def can_manage?(at)
    at.user_id == @current_user.id
  end

  def filter(ats, filter=nil)
    ats.where(visibility_for_filter(filter.to_s))
  end

  private

  def visibility_for_filter(filter)
    case filter
      when 'production'  then {visible_to: [:all, :owner]}
      when 'manage'      then {visible_to: :owner}
      else {}
    end
  end
end