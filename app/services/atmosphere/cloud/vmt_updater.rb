module Atmosphere
  class Cloud::VmtUpdater
    def initialize(tenant, image, options = {})
      @tenant = tenant
      @image = image
      @all = options[:all]
    end

    def execute
      perform_update!

      vmt
    end

    private

    attr_reader :image

    def perform_update!
      vmt.id_at_site = image.id
      vmt.name = image.name
      vmt.architecture = image.architecture
      vmt.state = image.status.downcase.to_sym
      vmt.tenants << @tenant if !(vmt.tenants.include? @tenant)
      if young?
        vmt.appliance_type ||= appliance_type
        vmt.version = version if version
        unless vmt.managed_by_atmosphere
          vmt.managed_by_atmosphere = vmt.appliance_type != nil
        end
      end

      state_changed_to_active = changed_to_active?

      if vmt.save
        follow_action if state_changed_to_active
      else
        logger.error "unable to create/update #{vmt.id} template because: #{vmt.errors.to_json}"
      end
    end

    def vmt
      # TODO: Hacky solution to get around the non-existence of Atmosphere::ComputeSite
      # Fix this after reinstating ComputeSite as a first-class AR

      @vmt ||= VirtualMachineTemplate.find_or_initialize_by(id_at_site: @image.id)
    end

    def logger
      Atmosphere.monitoring_logger
    end

    def appliance_type
      source_t_id, source_id_at_site = source_t_and_uuid

      if source_t_id && source_id_at_site
        ApplianceType.with_vmt(source_t_id, source_id_at_site).first
      end
    end

    def version
      source_vmt.version if source_vmt
    end

    def source_vmt
      source_t_id, source_id_at_site = source_t_and_uuid

      unless @source_vmt && source_t_id && source_id_at_site
        @source_vmt = VirtualMachineTemplate.
          on_tenant_with_src(source_t_id, source_id_at_site).
          first
      end

      @source_vmt
    end

    def source_t_and_uuid
      metadata = image.tags

      [metadata['source_t'], metadata['source_uuid']]
    end

    def young?
      @all || vmt.created_at.blank? ||
        vmt.created_at > Atmosphere.vmt_at_relation_update_period.hours.ago
    end

    def changed_to_active?
      vmt.state_changed? && vmt.state.active?
    end

    def follow_action
      Atmosphere::Cloud::RemoveOlderVmtWorker.perform_async(vmt.id)
    end
  end
end
