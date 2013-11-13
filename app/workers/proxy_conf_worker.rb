class ProxyConfWorker
  include Sidekiq::Worker

  sidekiq_options queue: :proxyconf

  def perform(compute_site_id)
    begin
      compute_site = ComputeSite.find(compute_site_id)
      generator = SiteProxyConf.new(compute_site)

      Sidekiq::Client.push('queue' => compute_site.site_id, 'class' => Redirus::Worker::Proxy, 'args' => [generator.generate, generator.properties])
      compute_site.update(regenerate_proxy_conf: false)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Compute site with id #{compute_site_id.to_s} is unknown. Proxy conf not generated."
    end
  end

  def self.regeneration_required(compute_site)
    compute_site.update(regenerate_proxy_conf: true)
  end

  def self.regenerate_proxy_confs
    ComputeSite.select(:id, :name).where(regenerate_proxy_conf: true).each do |cs|
      Rails.logger.info "Creating Proxy Conf regeneration task for #{cs.name}"
      perform_async(cs.id)
    end
  end
end