class ApplianceProxyConf
  def initialize(appliance)
    @appliance = appliance
  end

  def generate
    appl_proxy_configuration = []
    pm_templates.each do |pmt|
      appl_proxy_configuration << generate_redirection_and_port_mapping(pmt, ips, :http) if pmt.http?
      appl_proxy_configuration << generate_redirection_and_port_mapping( pmt, ips, :https) if pmt.https?
    end

    appl_proxy_configuration
  end

  def generate_redirection_and_port_mapping(pmt, ips, type)
    redirection = redirection(pmt, ips, type)
    properties = properties(pmt)
    redirection[:properties] = properties if properties.size > 0
    get_or_create_port_mapping(pmt, type, redirection[:path])
    redirection
  end

  def get_or_create_port_mapping(pmt, type, path)
    pm = @appliance.http_mappings.find_or_create_by(port_mapping_template: pmt, application_protocol: type)
    pm.url = path
    unless pm.save
      logger.error "Unable to save port mapping for #{@appliance.id} appliance, #{pmt.id} port mapping because of #{pm.errors.to_json}"
    end
  end

  def ips
    @ips ||= @appliance.virtual_machines.collect(&:ip)
  end

  def pm_templates
    @appliance.development? ? @appliance.dev_mode_property_set.port_mapping_templates : @appliance.appliance_type.port_mapping_templates
  end

  def redirection(pmt, ips, type)
    {
      path: path(pmt),
      workers: ips.collect { |ip| "#{ip}:#{pmt.target_port}"},
      type: type
    }
  end

  def properties(pmt)
    pmt.port_mapping_properties.collect { |prop| prop.to_s }
  end

  def path(pmt)
    "#{@appliance.appliance_set.id}/#{@appliance.appliance_configuration_instance.id}/#{pmt.service_name}"
  end
end