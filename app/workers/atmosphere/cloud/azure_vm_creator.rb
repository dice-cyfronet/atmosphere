module Atmosphere
  module Cloud
    class AzureVmCreator
      include Sidekiq::Worker

      sidekiq_options queue: :cloud
      sidekiq_options retry: false

      sidekiq_retries_exhausted do |msg|
        Raven.capture_message(
          "Failed to create a vm on Azure: #{msg}!",
          level: :error
        )
      end

      def perform(t_id, params)
        t = Tenant.find(t_id)
        c = t.cloud_client
        c.servers.create_orig(params)
      end
    end
  end
end
