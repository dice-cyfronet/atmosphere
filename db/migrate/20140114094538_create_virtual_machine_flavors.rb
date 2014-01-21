class CreateVirtualMachineFlavors < ActiveRecord::Migration
  def change
    create_table :virtual_machine_flavors do |t|
      t.string :flavor_name,            null:false
      t.float :cpu,                     null:true
      t.float :memory,                  null:true
      t.float :hdd,                     null:true
      t.integer :hourly_cost,           null:false

      t.belongs_to :compute_site
    end

    add_foreign_key :virtual_machine_flavors, :compute_sites

    # Add backreference in virtual_machines
    change_table :virtual_machines do |t|
      t.belongs_to :virtual_machine_flavor
    end

  end
end
