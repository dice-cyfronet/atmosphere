module Atmosphere
  class FlavorWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options retry: false

    def perform
      begin
        Rails.logger.debug "Updating flavor info for all tenants."
        FlavorManager::scan_all_tenants
      end
    end
  end
end