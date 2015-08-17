module Atmosphere
  module Cloud
    class OptimizeApplianceWorker
      include Sidekiq::Worker

      sidekiq_options queue: :cloud
      sidekiq_options retry: false

      sidekiq_retries_exhausted do |msg|
        Raven.capture_message(
          "Failed to optimize appliance: #{msg}!",
          level: :error
        )
      end

      def perform(appliance_id)
        appliance = Atmosphere::Appliance.find_by(id: appliance_id)
        Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute if appliance
      end
    end
  end
end
