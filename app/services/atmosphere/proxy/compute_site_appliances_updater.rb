module Atmosphere
  class Proxy::ComputeSiteAppliancesUpdater
    def initialize(compute_site, finder_class=AppliancesWithMappingOnComputeSite, updater_class=Proxy::ApplianceProxyUpdater)
      @compute_site = compute_site
      @finder_class = finder_class
      @updater_class = updater_class
    end

    def update
      affected_appliances.each do |appl|
        @updater_class.new(appl).update
      end
    end

    private

    def affected_appliances
      @finder_class.new(@compute_site).find
    end
  end
end