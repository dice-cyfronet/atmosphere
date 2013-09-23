class CreateVirtualMachineTemplates < ActiveRecord::Migration
  def change
    create_table :virtual_machine_templates do |t|
      t.string :id_at_site,               null: false
      t.string :name,                     null:false
      t.string :state,                    null:false

      t.references :compute_site,         null:false
      t.references :virtual_machine
      t.references :appliance_type

      t.timestamps
    end

    add_foreign_key :virtual_machine_templates, :compute_sites
    add_foreign_key :virtual_machine_templates, :virtual_machines
    add_foreign_key :virtual_machine_templates, :appliance_types
    add_index :virtual_machine_templates, [:compute_site_id, :id_at_site], unique: true, name: 'index_vm_tmpls_on_cs_id_and_id_at_site'
  end
end
