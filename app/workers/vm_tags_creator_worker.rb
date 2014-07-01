class VmTagsCreatorWorker
  include Sidekiq::Worker

  sidekiq_options queue: :tags
  sidekiq_options retry: 4

  sidekiq_retries_exhausted do |msg|
    capture_message(
      "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}. Manual intervention required!",
      level: :error
    )
  end

  def perform(server_id, site_id, tags_map)
    cs = ComputeSite.find(site_id)
    cloud_client = cs.cloud_client
    Rails.logger.debug { "Creating tags #{tags_map} for server #{server_id}" }
    begin
      cloud_client.create_tags_for_vm(server_id, tags_map)
    rescue Fog::Compute::AWS::NotFound, Fog::Compute::OpenStack::NotFound => e
      capture_message("Failed to annotate #{server_id} because of #{e.message}- will try to retry")
      raise e
    end
    Rails.logger.debug { "Successfuly created tags for server #{server_id}" }
  end

  def capture_message(msg, options = {})
    Raven.capture_message(
      msg,
      level: options[:level] || :warning,
      tags: {
        type: 'vm_tagging'
      }
    )
  end
end