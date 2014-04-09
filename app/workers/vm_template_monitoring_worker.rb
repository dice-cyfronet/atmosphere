class VmTemplateMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring
  sidekiq_options :retry => false

  def perform(site_id)
    begin
      logger.info "#{jid}: Starting VMTs monitoring for site #{site_id}"
      site = ComputeSite.find(site_id)
      filters = site.template_filters ? JSON.parse(site.template_filters) : nil
      logger.info "#{jid}: getting images state for site #{site_id} from compute site"
      update_images(site, site.cloud_client.images.all(filters))
      logger.info "#{jid}: updating VMTs finished for site #{site_id}"
    rescue Excon::Errors::HTTPStatusError => e
      logger.error "#{jid}: Unable to perform VMTs monitoring job: #{e}"
    end
  end

  # For AWS it is necessary to filter images while listing them: imgs=cloud_client.describe_images({'Owner'=>'take this number from AWS console'})

  private

  def update_images(site, images)
    logger.info "#{jid}: updating VMTs"
    all_site_templates = site.virtual_machine_templates.to_a
    images.each do |image|
      template = site.virtual_machine_templates.find_or_initialize_by(id_at_site: image.id)
      template.id_at_site =  image.id
      template.name = image.name
      template.architecture = image.architecture
      template.state = image.status.downcase.to_sym

      all_site_templates.delete template

      unless template.save
        logger.error "#{jid}: unable to create/update #{template.id} template because: #{template.errors.to_json}"
      end
    end

    #remove deleted templates
    all_site_templates.each { |t| t.destroy(false) }
  end

  def logger
    Air.monitoring_logger
  end
end