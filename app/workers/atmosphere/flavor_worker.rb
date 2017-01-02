module Atmosphere
  class FlavorWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options retry: false

    def perform(tenant_id)
      if tenant = Atmosphere::Tenant.find_by(id: tenant_id)
        Rails.logger.debug "Updating flavor for #{tenant_id} tenant."
        FlavorUpdater.new(tenant).execute
      end
    end
  end
end
