module Atmosphere
  class Proxy::ComputeSiteUrlUpdater
    def initialize(compute_site, mappings_finder_class=::ComputeSiteHttpMappings, url_generator_class=Proxy::UrlGenerator)
      @compute_site = compute_site
      @mappings_finder_class = mappings_finder_class
      @url_generator_class = url_generator_class
    end

    def update
      finder.find.each do |mapping|
        mapping.url = url_generator.url_for(mapping)
        mapping.save || log_error(mapping)
      end
    end

    private

    def finder
      @finder ||= @mappings_finder_class.new(@compute_site)
    end

    def url_generator
      @url_generator ||= @url_generator_class.new(@compute_site)
    end

    def log_error(mapping)
      Rails.logger.error("Unable to update mapping url because of #{mapping.errors}")
    end
  end
end