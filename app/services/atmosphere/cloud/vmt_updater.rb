module Atmosphere
  class Cloud::VmtUpdater
    def initialize(site, image, options = {})
      @site = site
      @image = image
      @all = options[:all]
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
      if young?
        vmt.appliance_type ||= appliance_type
        unless vmt.managed_by_atmosphere
          vmt.managed_by_atmosphere = vmt.appliance_type != nil
        end
      end

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

    def appliance_type
      metadata = image.tags
      source_cs_id, source_uuid = metadata['source_cs'], metadata['source_uuid']

      if source_cs_id && source_uuid
        ApplianceType.with_vmt(source_cs_id, source_uuid).first
      end
    end

    def young?
      @all || vmt.created_at.blank? ||
        vmt.created_at > Air.config.vmt_at_relation_update_period.hours.ago
    end
  end
end
