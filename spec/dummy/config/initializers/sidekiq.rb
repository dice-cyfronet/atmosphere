sidekiq_connection = {
  url: 'redis://localhost:6379',
  namespace: 'atmosphere'
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_connection
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_connection
end
