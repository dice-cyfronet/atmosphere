class CreateVirtualMachines < ActiveRecord::Migration
  def change
    create_table :atmosphere_virtual_machines do |t|
      t.string :id_at_site,               null: false
      t.string :name,                     null: false
      t.string :state,                    null: false
      t.string :ip
      t.boolean :managed_by_atmosphere,   null: false, default: false

      t.references :compute_site,         null: false

      t.timestamps
    end

    add_foreign_key :atmosphere_virtual_machines,
                    :atmosphere_compute_sites,
                    column: 'compute_site_id',
                    name: 'atmo_vm_cs_fk'

    add_index :atmosphere_virtual_machines,
              [:compute_site_id, :id_at_site],
              name: 'atmo_vm_cs_id_id_at_site_ix',
              unique: true

    # Linking table supporting the m:n relationship between appliances and virtual_machines.
    # Also functions as an ActiveRecord in its own right.
    create_table :atmosphere_deployments do |t|
      t.belongs_to :virtual_machine
      t.belongs_to :appliance
    end
  end
end
