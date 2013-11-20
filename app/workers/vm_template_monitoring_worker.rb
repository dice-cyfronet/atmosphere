class VmTemplateMonitoringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :monitoring
  sidekiq_options :retry => false

  def perform(site_id)
    begin
      site = ComputeSite.find(site_id)
      update_images(site, site.cloud_client.images)
    rescue Excon::Errors::HTTPStatusError => e
      Rails.logger.error "Unable to perform Templates monitoring job: #{e}"
    end
  end

  # For AWS it is necessary to filter images while listing them: imgs=cloud_client.describe_images({'Owner'=>'take this number from AWS console'})

  private

  def update_images(site, images)
    all_site_templates = site.virtual_machine_templates.to_a
    images.each do |image|
      template = site.virtual_machine_templates.find_or_initialize_by(id_at_site: image.id)
      template.id_at_site =  image.id
      template.name = image.name
      template.state = image.status.downcase.to_sym

      all_site_templates.delete template

      unless template.save
        error("unable to create/update #{template.id} template because: #{template.errors.to_json}")
      end
    end

    #remove deleted templates
    all_site_templates.each { |t| t.destroy(false) }
  end

  def error(message)
    Rails.logger.error "MONITORING: #{message}"
  end
end