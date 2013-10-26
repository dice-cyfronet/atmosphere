class HttpMappingProxyConfGenerator
  # PN 2013-10-21
  # Generates data structure required by ProxyConf to set up redirections
  # for all VMs running on a given CloudSite.
  # Parameterized by cloud site ID

  def run(compute_site_id)
    appliances = compute_site_appliances(compute_site(compute_site_id))
    appliances.collect do |appliance|
      appliance_proxy_configuration(appliance)
    end.flatten.uniq
  end

  private

  def compute_site_appliances(cs)
    Appliance.joins(:virtual_machines).where(virtual_machines: {compute_site: cs})
  end

  def compute_site(compute_site_id)
    begin
      ComputeSite.find(compute_site_id)
    rescue ActiveRecord::RecordNotFound
      raise Air::UnknownComputeSite.new "Compute site with id #{compute_site_id.to_s} is unknown."
    end
  end

  def appliance_proxy_configuration(appliance)
    ips = ips(appliance)
    appl_proxy_configuration = []
    pm_templates(appliance).each do |pmt|
      appl_proxy_configuration << generate_redirection_and_port_mapping(appliance, pmt, ips, :http) if pmt.http?
      appl_proxy_configuration << generate_redirection_and_port_mapping(appliance, pmt, ips, :https) if pmt.https?
    end

    appl_proxy_configuration
  end

  def generate_redirection_and_port_mapping(appliance, pmt, ips, type)
    redirection = redirection(appliance, pmt, ips, type)
    get_or_create_port_mapping(appliance, pmt, type, redirection[:path])
    redirection
  end

  def get_or_create_port_mapping(appliance, pmt, type, path)
    pm = appliance.http_mappings.find_or_create_by(port_mapping_template: pmt, application_protocol: type)
    pm.url = path
    unless pm.save
      logger.error "Unable to save port mapping for #{appliance.id} appliance, #{pmt.id} port mapping because of #{pm.errors.to_json}"
    end
  end

  def ips(appliance)
    appliance.virtual_machines.select(:ip).collect {|vm| vm.ip}
  end

  def pm_templates(appliance)
    appliance.development? ? appliance.dev_mode_property_set.port_mapping_templates : appliance.appliance_type.port_mapping_templates
  end

  def redirection(appliance, pmt, ips, type)
    {
      path: path(appliance, pmt),
      workers: ips.collect { |ip| "#{ip}:#{pmt.target_port}"},
      type: type
    }
  end

  def path(appliance, pmt)
    "#{appliance.appliance_set.id}/#{appliance.appliance_configuration_instance.id}/#{pmt.service_name}"
  end
end