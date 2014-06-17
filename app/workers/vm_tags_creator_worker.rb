class VmTagsCreatorWorker
  include Sidekiq::Worker

  sidekiq_options queue: :tags
  sidekiq_options retry: 4

  def perform(server_id, site_id, tags_map)
    cs = ComputeSite.find(site_id)
    cloud_client = cs.cloud_client
    Rails.logger.debug { "Creating tags #{tags_map} for server #{server_id}" }
    begin
      cloud_client.create_tags_for_vm(server_id, tags_map)
    rescue Fog::Compute::AWS::NotFound, Fog::Compute::OpenStack::NotFound => e
      Raven.capture_exception(e)
    end
    Rails.logger.debug { "Successfuly created tags for server #{server_id}" }
  end

end