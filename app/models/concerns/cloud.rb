module Cloud extend ActiveSupport::Concern

  module ClassMethods

    def get_cloud_client_for_site(site_id)
      cloud_site_conf = Air::Application.config.cloud_sites[site_id]
      @cloud_client = Fog::Compute.new(cloud_site_conf)
      Rails.logger.debug "Returning cloud client #{@cloud_client.class}"
      @cloud_client
    end

  end
end