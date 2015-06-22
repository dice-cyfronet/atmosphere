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

      def perform(cs_id, params)
        cs = ComputeSite.find(cs_id)
        c = cs.cloud_client
        c.servers.create_orig(params)
      end
    end
  end
end
