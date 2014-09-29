module Atmosphere
  class EndpointsVisibleToUser
    def initialize(endpoints = Endpoint, user)
      @endpoints = endpoints
      @user = user
    end

    def find
      query = owned.or(visible_to_all)
      query = query.or(visible_to_developer) if @user.developer?

      endpoints.where(query)
    end

    private

    def endpoints
      @endpoints.includes(
        port_mapping_template: {
          appliance_type: {},
          dev_mode_property_set: { appliance: :appliance_set }
        }
      ).references(:appliance_types, :appliance_sets)
    end

    def owned
      owned_at.or(owned_dev_appliance)
    end

    def owned_at
      at_table[:user_id].eq(@user.id)
    end

    def owned_dev_appliance
      as_table[:user_id].eq(@user.id)
    end

    def visible_to_all
      at_table[:visible_to].eq(:all)
    end

    def visible_to_developer
      at_table[:visible_to].eq(:developer)
    end

    def at_table
      ApplianceType.arel_table
    end

    def as_table
      ApplianceSet.arel_table
    end
  end
end