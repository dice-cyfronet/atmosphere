Sidekiq.configure_server do |config|
  config.redis = {
    url: Atmosphere.sidekiq.url,
    namespace: Atmosphere.sidekiq.namespace
  }
  config.poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: Atmosphere.sidekiq.url,
    namespace: Atmosphere.sidekiq.namespace
  }
end
