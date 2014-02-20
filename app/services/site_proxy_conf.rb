# Generates data structure required by ProxyConf to set up redirections
# for all VMs running on a given CloudSite.
# Parameterized by compute site
class SiteProxyConf
  def initialize(compute_site)
    @compute_site = compute_site
  end

  def generate
    Appliance.started_on_site(@compute_site).collect do |appliance|
      ApplianceProxyConf.new(appliance, @compute_site).generate
    end.flatten.uniq
  end

  def properties
    @compute_site.port_mapping_properties.collect(&:to_s)
  end
end