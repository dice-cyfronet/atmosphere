module Atmosphere
  class VmTemplateMonitoringWorker
    include Sidekiq::Worker

    sidekiq_options queue: :monitoring
    sidekiq_options retry: false

    def perform(tenant_id)
      begin
        logger.debug { "#{jid}: Starting VMTs monitoring for tenant #{tenant_id}" }
        tenant = Tenant.find(tenant_id)
        filters = tenant.template_filters ? JSON.parse(tenant.template_filters) : {}

        logger.debug { "#{jid}: getting images state for tenant #{tenant_id} from tenant" }

        images = if filters.empty?
                   tenant.cloud_client.images.all
                 else
                   tenant.cloud_client.images.all(filters)
                 end

        update_images(tenant, images)

        logger.debug { "#{jid}: updating VMTs finished for tenant #{tenant_id}" }
      rescue Excon::Errors::HTTPStatusError => e
        logger.error "#{jid}: Unable to perform VMTs monitoring job: #{e}"
      end
    end

    # For AWS it is necessary to filter images while listing them: imgs=cloud_client.describe_images({'Owner'=>'take this number from AWS console'})

    private

    def update_images(tenant, images)
      logger.debug { "#{jid}: updating VMTs" }
      all_tenant_templates = tenant.virtual_machine_templates.to_a
      images.each do |image|
        updated_vmt = Cloud::VmtUpdater.new(tenant, image).execute
        all_tenant_templates.delete(updated_vmt)
      end

      #remove deleted templates
      all_tenant_templates.each do |vmt|

        puts "+++Figuring out what to do with VMT #{vmt.inspect}"
        # Reload and delete VMT only if it has no more linked tenants (and is not young).
        if vmt.old?
          # Unlink VMT from current tenant first
          tenant.virtual_machine_templates = tenant.virtual_machine_templates-[vmt]
          if vmt.tenants.blank?
            vmt.destroy(false)
          end
        end
      end
    end

    def logger
      Atmosphere.monitoring_logger
    end
  end
end