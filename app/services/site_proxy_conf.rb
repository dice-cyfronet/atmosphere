# Generates data structure required by ProxyConf to set up redirections
# for all VMs running on a given CloudSite.
# Parameterized by compute site
class SiteProxyConf
  def initialize(compute_site)
    @compute_site = compute_site
  end

  def generate
    proxy_confs = compute_site_appliances.collect do |appliance|
      ApplianceProxyConf.new(appliance).generate
    end.flatten.uniq

    proxy_confs
  end

  def properties
    @compute_site.port_mapping_properties.collect { |prop| prop.to_s }
  end

  private

  def compute_site_appliances
    Appliance.joins(:virtual_machines).where(virtual_machines: {compute_site: @compute_site})
  end
end