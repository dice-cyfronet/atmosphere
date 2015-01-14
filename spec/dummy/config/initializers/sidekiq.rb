sidekiq_connection = {
  url: Settings.sidekiq.url,
  namespace: Settings.sidekiq.namespace
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_connection
  config.poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_connection
end
