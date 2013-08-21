class CreateVirtualMachineTemplates < ActiveRecord::Migration
  def change
    create_table :virtual_machine_templates do |t|
      t.string :id_at_site,               null: false
      t.string :name,                     null:false
      t.string :state,                    null:false

      t.references :compute_site,         null:false
      t.references :virtual_machine

      t.timestamps
    end

    add_foreign_key :virtual_machine_templates, :compute_sites
    add_foreign_key :virtual_machine_templates, :virtual_machines
  end
end
