class AbilityBuilder
  def initialize(ability, user)
    @ability = ability
    @user = user
  end

  def add_user_abilities!; end
  def add_developer_abilities!; end
  def add_anonymous_abilities!; end

  protected

  attr_reader :ability, :user

  def pdp
    Air.config.at_pdp_class.new(@user)
  end

  def can(action = nil, subject = nil, conditions = nil, &block)
    ability.can(action, subject, conditions, &block)
  end
end