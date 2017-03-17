#
# Ability builder simplifying the way how cancan model abilities are defined
# for concrete group of users (normal logged in users, developers and
# anonymous users).
#
module Atmosphere
  class AbilityBuilder
    def initialize(ability, user, pdp_class)
      @ability = ability
      @user = user
      @pdp_class = pdp_class
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
    delegate :can, to: :ability

    #
    # Pdp allowing to filter number of Appliance Types
    # presented to the user.
    #
    def pdp
      Atmosphere.at_pdp(@user)
    end
  end
end
