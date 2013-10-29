class ProxyConfWorker

  def perform(compute_site_id)
    compute_site = compute_site(compute_site_id)
    generator = SiteProxyConf.new(compute_site)

    Sidekiq::Client.push('queue' => compute_site.site_id, 'class' => Redirus::Worker::Proxy, 'args' => [generator.generate, generator.properties])
  end

  def compute_site(compute_site_id)
    begin
      ComputeSite.find(compute_site_id)
    rescue ActiveRecord::RecordNotFound
      raise Air::UnknownComputeSite.new "Compute site with id #{compute_site_id.to_s} is unknown."
    end
  end
end