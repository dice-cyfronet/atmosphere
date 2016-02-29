class Atmosphere::Admin::MigrationJobsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :migration_job,
                              class: 'Atmosphere::MigrationJob'

  def index
    @migration_jobs = @migration_jobs.includes(:appliance_type,
                                               :tenant_source,
                                               :tenant_destination)
  end
end
