#
# Find http mappings on given compute site.
#
module Atmosphere
  class ComputeSiteHttpMappings
    def initialize(compute_site)
      @compute_site = compute_site
    end

    #
    # Find all http mappings registered on given compute site.
    #
    # Number of http mappings can be limited by providing
    # :protocol options (:http or :https).
    #
    def find(options = {})
      find_hsh = { compute_site: @compute_site }
      find_hsh[:application_protocol] = options[:protocol] if options[:protocol]

      HttpMapping.where(find_hsh)
    end
  end
end