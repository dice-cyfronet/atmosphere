Sidekiq.configure_server do |config|
  config.redis = {
    url: Atmosphere.redis_url,
    namespace: Atmosphere.redis_namespace
  }
  config.poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: Atmosphere.redis_url,
    namespace: Atmosphere.redis_namespace
  }
end
