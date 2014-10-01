module Atmosphere
  class VmTemplateMonitoringWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options :retry => false

    def perform(site_id)
      begin
        logger.debug { "#{jid}: Starting VMTs monitoring for site #{site_id}" }
        site = ComputeSite.find(site_id)
        filters = site.template_filters ? JSON.parse(site.template_filters) : nil
        logger.debug { "#{jid}: getting images state for site #{site_id} from compute site" }
        update_images(site, site.cloud_client.images.all(filters))
        logger.debug { "#{jid}: updating VMTs finished for site #{site_id}" }
      rescue Excon::Errors::HTTPStatusError => e
        logger.error "#{jid}: Unable to perform VMTs monitoring job: #{e}"
      end
    end

    # For AWS it is necessary to filter images while listing them: imgs=cloud_client.describe_images({'Owner'=>'take this number from AWS console'})

    private

    def update_images(site, images)
      logger.debug { "#{jid}: updating VMTs" }
      all_site_templates = site.virtual_machine_templates.to_a
      images.each do |image|
        updated_vmt = Cloud::VmtUpdater.new(site, image).update

        all_site_templates.delete(updated_vmt)
      end

      #remove deleted templates
      all_site_templates.each do |vmt|
        vmt.destroy(false) if vmt.old?
      end
    end

    def logger
      Air.monitoring_logger
    end
  end
end