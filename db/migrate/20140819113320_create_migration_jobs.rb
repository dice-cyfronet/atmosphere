class CreateMigrationJobs < ActiveRecord::Migration
  def change
    create_table :atmosphere_migration_jobs do |t|
      t.references :appliance_type
      t.references :compute_site_source
      t.references :compute_site_destination
      t.text :status

      t.timestamps
    end

    add_foreign_key :atmosphere_migration_jobs,
                    :atmosphere_appliance_types,
                    column: 'appliance_type_id',
                    name: 'atmo_mj_at_fk'

    add_foreign_key :atmosphere_migration_jobs,
                    :atmosphere_compute_sites,
                    column: 'compute_site_source_id',
                    name: 'atmo_mj_css_fk'

    add_foreign_key :atmosphere_migration_jobs,
                    :atmosphere_compute_sites,
                    column: 'compute_site_destination_id',
                    name: 'atmo_mj_csd_fk'
  end
end
