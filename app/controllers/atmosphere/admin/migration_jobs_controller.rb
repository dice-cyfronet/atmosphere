class Atmosphere::Admin::MigrationJobsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :migration_job,
                              class: 'Atmosphere::MigrationJob'

  before_filter :load_deps

  def index
  end

  private

  def load_deps
    @migration_jobs = @migration_jobs.includes(:appliance_type,
                                               :compute_site_source,
                                               :compute_site_destination)
    @migration_jobs = @migration_jobs.decorate
  end
end
