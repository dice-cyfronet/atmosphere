class ProxyConfWorker

  def perform(compute_site_id)
    begin
      compute_site = ComputeSite.find(compute_site_id)
      generator = SiteProxyConf.new(compute_site)

      Sidekiq::Client.push('queue' => compute_site.site_id, 'class' => Redirus::Worker::Proxy, 'args' => [generator.generate, generator.properties])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Compute site with id #{compute_site_id.to_s} is unknown. Proxy conf not generated."
    end
  end
end