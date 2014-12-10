module Atmosphere
  module Cloud
    class RemoveOlderVmtWorker
      include Sidekiq::Worker

      sidekiq_options queue: :cloud
      sidekiq_options retry: 4

      sidekiq_retries_exhausted do |msg|
        Raven.capture_message(
          "Failed #{msg['class']} with #{msg['args']}: "\
          "#{msg['error_message']}. Manual intervention required!",
          level: :error,
          tags: { type: 'vmt' }
        )
      end

      def perform(vmt_id)
        vmt = Atmosphere::VirtualMachineTemplate.find_by(id: vmt_id)

        Atmosphere::Cloud::RemoveOlderVmt.new(vmt).execute if vmt
      end
    end
  end
end
