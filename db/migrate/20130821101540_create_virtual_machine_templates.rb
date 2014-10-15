class CreateVirtualMachineTemplates < ActiveRecord::Migration
  def change
    create_table :atmosphere_virtual_machine_templates do |t|
      t.string :id_at_site,               null: false
      t.string :name,                     null:false
      t.string :state,                    null:false
      t.boolean :managed_by_atmosphere,   null: false, default: false

      t.references :compute_site,         null:false
      t.references :virtual_machine
      t.references :appliance_type

      t.timestamps
    end

    add_foreign_key :atmosphere_virtual_machine_templates,
                    :atmosphere_compute_sites,
                    column: 'compute_site_id',
                    name: 'atmo_vmt_cs_fk'

    add_foreign_key :atmosphere_virtual_machine_templates,
                    :atmosphere_virtual_machines,
                    column: 'virtual_machine_id',
                    name: 'atmo_vmt_vm_fk'

    add_foreign_key :atmosphere_virtual_machine_templates,
                    :atmosphere_appliance_types,
                    column: 'appliance_type_id',
                    name: 'atmo_vmt_at_fk'

    add_index :atmosphere_virtual_machine_templates,
              [:compute_site_id, :id_at_site],
              unique: true,
              name: 'atmo_vm_tmpls_on_cs_id_and_id_at_site_ix'
  end
end
