class AddVmtToMigrationStatus < ActiveRecord::Migration
  def change
    add_column :atmosphere_migration_jobs,
               :virtual_machine_template_id,
               :int

    add_foreign_key :atmosphere_migration_jobs,
                    :atmosphere_virtual_machine_templates,
                    column: 'virtual_machine_template_id',
                    name: 'atmo_mj_vmt_fk'

    remove_index :atmosphere_migration_jobs,
                 name: 'atmo_mj_ix'
    
    add_index :migration_jobs,
              [:appliance_type_id, :virtual_machine_template_id, :compute_site_source_id, :compute_site_destination_id],
              unique: true,
              name: 'atmo_mj_ix'
  end
end
