class ApplianceProxyConf
  def initialize(appliance, http_proxy_url, https_proxy_url)
    @appliance = appliance
    @http_proxy_url = http_proxy_url
    @https_proxy_url = https_proxy_url
  end

  def generate
    ips.empty? ? [] : generate_proxy_conf
  end

  private

  def generate_proxy_conf
    pm_templates.inject([]) do |tab, pmt|
      tab << generate_redirection_and_port_mapping(pmt, :http) if pmt.http?
      tab << generate_redirection_and_port_mapping( pmt, :https) if pmt.https?
      tab
    end
  end

  def generate_redirection_and_port_mapping(pmt, type)
    redirection = redirection(pmt, type)
    properties = properties(pmt)
    redirection[:properties] = properties if properties.size > 0
    get_or_create_port_mapping(pmt, type, full_path(type, redirection[:path]))
    redirection
  end

  def full_path(type, postfix)
    "#{proxy_url(type)}/#{postfix}"
  end

  def proxy_url(type)
    type == :http ? @http_proxy_url : @https_proxy_url
  end

  def get_or_create_port_mapping(pmt, type, path)
    pm = @appliance.http_mappings.find_or_create_by(port_mapping_template: pmt, application_protocol: type)
    pm.url = path
    unless pm.save
      logger.error "Unable to save port mapping for #{@appliance.id} appliance, #{pmt.id} port mapping because of #{pm.errors.to_json}"
    end
  end

  def ips
    @ips ||= @appliance.virtual_machines.collect(&:ip).reject(&:blank?)
  end

  def pm_templates
    @appliance.development? ? @appliance.dev_mode_property_set.port_mapping_templates : @appliance.appliance_type.port_mapping_templates
  end

  def redirection(pmt, type)
    {
      path: path(pmt),
      workers: ips.collect { |ip| "#{ip}:#{pmt.target_port}"},
      type: type
    }
  end

  def properties(pmt)
    pmt.port_mapping_properties.collect(&:to_s)
  end

  def path(pmt)
    "#{@appliance.id}/#{pmt.service_name}"
  end
end