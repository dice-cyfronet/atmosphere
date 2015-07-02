#
# Find http mappings on given tenant.
#
module Atmosphere
  class TenantHttpMappings
    def initialize(tenant)
      @tenant = tenant
    end

    #
    # Find all http mappings registered on given tenant.
    #
    # Number of http mappings can be limited by providing
    # :protocol options (:http or :https).
    #
    def find(options = {})
      find_hsh = { tenant: @tenant }
      find_hsh[:application_protocol] = options[:protocol] if options[:protocol]

      HttpMapping.where(find_hsh)
    end
  end
end