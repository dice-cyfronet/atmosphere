#
# Find all appliances which http mapping is registered on given compute site.
#
module Atmosphere
  class AppliancesWithMappingOnComputeSite
    def initialize(compute_site)
      @compute_site = compute_site
    end

    def find
      Appliance.joins(:http_mappings).where(
          atmosphere_http_mappings: { compute_site_id: @compute_site.id }
        )
    end
  end
end