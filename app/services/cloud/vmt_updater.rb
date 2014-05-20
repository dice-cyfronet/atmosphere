class Cloud::VmtUpdater
  def initialize(site, image)
    @site = site
    @image = image
  end

  def update
    perform_update!

    vmt
  end

  private

  attr_reader :image

  def perform_update!
    vmt.id_at_site =  image.id
    vmt.name = image.name
    vmt.architecture = image.architecture
    vmt.state = image.status.downcase.to_sym

    unless vmt.save
      logger.error "unable to create/update #{vmt.id} template because: #{vmt.errors.to_json}"
    end
  end

  def vmt
    @vmt ||= @site.virtual_machine_templates
      .find_or_initialize_by(id_at_site: @image.id)
  end

  def logger
    Air.monitoring_logger
  end
end