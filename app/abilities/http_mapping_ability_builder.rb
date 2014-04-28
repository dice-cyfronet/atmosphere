#
# Http mapping abilities.
#
class HttpMappingAbilityBuilder < AbilityBuilder
  def add_user_abilities!
    can :read, HttpMapping,
        appliance: { appliance_set: { user_id: user.id } }
  end
end
