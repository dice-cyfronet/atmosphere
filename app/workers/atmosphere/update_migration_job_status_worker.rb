module Atmosphere
  class UpdateMigrationJobStatusWorker
    include Sidekiq::Worker

    sidekiq_options queue: :migration_jobs
    sidekiq_options retry: false

    def perform(vmt_uuid, source_site_id, dest_site_id, status)
      vmt = VirtualMachineTemplate.find_by id_at_site: vmt_uuid
      source_cs = ComputeSite.find_by site_id: source_site_id
      dest_cs = ComputeSite.find_by site_id: dest_site_id

      migration_job = MigrationJob.find_or_initialize_by(
                        appliance_type_id: vmt.appliance_type_id,
                        virtual_machine_template: vmt,
                        compute_site_source: source_cs,
                        compute_site_destination: dest_cs)
      migration_job.status = "#{migration_job.status} #{status}"
      migration_job.save
    end
  end
end
