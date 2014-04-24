#
# Ability builder simplifying the way how cancan model abilities are defined
# for concrete group of users (normal logged in users, developers and
# anonymous users).
#
class AbilityBuilder
  def initialize(ability, user)
    @ability = ability
    @user = user
  end

  #
  # Loggin in user abilities for concreate model.
  # Empty by default.
  #
  def add_user_abilities!; end

  #
  # Developer abilities for concreate model.
  # Empty by default.
  #
  def add_developer_abilities!; end

  #
  # Anonymous user abilities for concreate model.
  # Empty by default.
  #
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
