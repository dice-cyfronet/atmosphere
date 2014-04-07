redis_url = Air.config.sidekiq.url
namespace = Air.config.sidekiq.namespace

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, namespace: namespace }
  config.poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, namespace: namespace }
end
