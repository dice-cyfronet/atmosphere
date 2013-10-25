class HttpMappingProxyConfGenerator
  # PN 2013-10-21
  # Generates data structure required by ProxyConf to set up redirections
  # for all VMs running on a given CloudSite.
  # Parameterized by cloud site ID

  def run(compute_site_id)

    begin
      cs = ComputeSite.find(compute_site_id)
    rescue ActiveRecord::RecordNotFound
      raise Air::UnknownComputeSite.new "Compute site with id #{compute_site_id.to_s} is unknown."
    end

    proxy_configuration = []
    appliances = Appliance.joins(:virtual_machines).where(virtual_machines: {compute_site: cs})

    appliances.each do |appliance|
      ips = appliance.virtual_machines.select(:ip).collect {|vm| vm.ip}
      pm_templates = appliance.appliance_type.port_mapping_templates
      pm_templates.each do |pmt|
        proxy_configuration << generate_redirection_and_port_mapping(appliance, pmt, ips, :http) if pmt.http?
        proxy_configuration << generate_redirection_and_port_mapping(appliance, pmt, ips, :https) if pmt.https?
      end
    end

    proxy_configuration.uniq
  end

  private

  def generate_redirection_and_port_mapping(appliance, pmt, ips, type)
    redirection = redirection(appliance, pmt, ips, type)
    pm = appliance.http_mappings.find_or_create_by(port_mapping_template: pmt, application_protocol: type)
    pm.url = redirection[:path]
    unless pm.save
      logger.error "Unable to save port mapping for #{appliance.id} appliance, #{pmt.id} port mapping because of #{pm.errors.to_json}"
    end

    redirection
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