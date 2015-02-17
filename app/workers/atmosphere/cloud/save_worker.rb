module Atmosphere
  module Cloud
    class SaveWorker
      include Sidekiq::Worker

      sidekiq_options queue: :cloud
      sidekiq_options retry: false

      sidekiq_retries_exhausted do |msg|
        Raven.capture_message(
          "Failed #{msg['class']} with #{msg['args']}: "\
          "#{msg['error_message']}. Appliance type not saved!",
          level: :error,
          tags: { type: 'vmt' }
        )
      end

      def perform(appl_id, at_id)
        appl = Atmosphere::Appliance.find_by(id: appl_id)
        at = Atmosphere::ApplianceType.find_by(id: at_id)

        Atmosphere::Cloud::Save.new(appl, at).execute if appl && at
      end
    end
  end
end
