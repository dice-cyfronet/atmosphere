module Atmosphere
  class Proxy::UrlGenerator

    def initialize(compute_site)
      @compute_site = compute_site
    end

    def self.glue(base_url, prefix)
      uri = URI(base_url)

      "#{uri.scheme}://#{prefix}.#{uri.host}"
    end

    def url_for(http_mapping)
      Proxy::UrlGenerator.glue(
        base_url(http_mapping),
        http_mapping.proxy_name)
    end

    def base_url(http_mapping)
      http_mapping.application_protocol.http? ?
        @compute_site.http_proxy_url :
        @compute_site.https_proxy_url
    end
  end
end