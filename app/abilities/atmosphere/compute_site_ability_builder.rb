#
# Compute Site abilities.
#
class ComputeSiteAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :read, ComputeSite
  end
end
