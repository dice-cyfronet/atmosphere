module Atmosphere
  class UpdateMigrationJobStatusWorker
    include Sidekiq::Worker

    sidekiq_options queue: :feedback
    sidekiq_options retry: false

    def perform(vmt_uuid, source_tenant_id, dest_tenant_id, status)
      vmt = VirtualMachineTemplate.find_by(id_at_site: vmt_uuid)
      source_t = Tenant.find_by(tenant_id: source_tenant_id)
      dest_t = Tenant.find_by(tenant_id: dest_tenant_id)

      migration_job = MigrationJob.find_or_initialize_by(
                        virtual_machine_template: vmt,
                        tenant_source: source_t,
                        tenant_destination: dest_t)
      migration_job.appliance_type_id = vmt.appliance_type_id
      migration_job.status = "#{migration_job.status} #{status}"
      migration_job.save
    end
  end
end
