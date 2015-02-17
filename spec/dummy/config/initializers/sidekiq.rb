sidekiq_connection = {
  url: 'redis://localhost:6379',
  namespace: 'atmosphere'
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_connection
  config.poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_connection
end
