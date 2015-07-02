module Atmosphere
  class Proxy::TenantAppliancesUpdater
    def initialize(tenant, finder_class=AppliancesWithMappingOnTenant, updater_class=Proxy::ApplianceProxyUpdater)
      @tenant = tenant
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
      @finder_class.new(@tenant).find
    end
  end
end