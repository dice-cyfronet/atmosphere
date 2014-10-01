module Atmosphere
  class MiCacheCleanerWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options :retry => false

    def perform
      Devise::Strategies::MiTokenAuthenticatable.clean_cache!
    end
  end
end