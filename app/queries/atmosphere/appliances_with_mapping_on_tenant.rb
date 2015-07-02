#
# Find all appliances which http mapping is registered on given tenant.
#
module Atmosphere
  class AppliancesWithMappingOnTenant
    def initialize(tenant)
      @tenant = tenant
    end

    def find
      Appliance.joins(:http_mappings).where(
          atmosphere_http_mappings: { tenant_id: @tenant.id }
        )
    end
  end
end