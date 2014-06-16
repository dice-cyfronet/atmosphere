class VmTagsCreatorWorker
  include Sidekiq::Worker

  sidekiq_options queue: :tags
  sidekiq_options retry: 4

  def perform(server_id, site_id, tags_map)
    cs = ComputeSite.find(site_id)
    return unless cs.technology == 'aws'
    cloud_client = cs.cloud_client
    Rails.logger.info { "Creating tags #{tags_map} for server #{server_id}" }
    begin
      cloud_client.create_tags(server_id, tags_map)
    rescue Fog::Compute::AWS::NotFound => e
      Raven.capture_exception(e)
    end
  end

end