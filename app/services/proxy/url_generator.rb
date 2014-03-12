class Proxy::UrlGenerator

  def initialize(compute_site)
    @compute_site = compute_site
  end

  def url_for(http_mapping)
    uri = URI(base_url(http_mapping.application_protocol))

    "#{uri.scheme}://#{http_mapping.proxy_name}.#{uri.host}"
  end

  private

  def base_url(type)
    type.http? ?
      @compute_site.http_proxy_url :
      @compute_site.https_proxy_url
  end
end