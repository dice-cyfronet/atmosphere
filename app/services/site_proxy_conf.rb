# Generates data structure required by ProxyConf to set up redirections
# for all VMs running on a given CloudSite.
# Parameterized by cloud site ID
class SiteProxyConf
  def initialize(compute_site_id)
    @compute_site = compute_site(compute_site_id)
  end

  def generate
    compute_site_appliances.collect do |appliance|
      ApplianceProxyConf.new(appliance).generate
    end.flatten.uniq
  end

  private

  def compute_site_appliances
    Appliance.joins(:virtual_machines).where(virtual_machines: {compute_site: @compute_site})
  end

  def compute_site(compute_site_id)
    begin
      ComputeSite.find(compute_site_id)
    rescue ActiveRecord::RecordNotFound
      raise Air::UnknownComputeSite.new "Compute site with id #{compute_site_id.to_s} is unknown."
    end
  end
end