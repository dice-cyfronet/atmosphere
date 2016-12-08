class CreateVirtualMachineFlavors < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_virtual_machine_flavors do |t|
      t.string :flavor_name,            null:false
      t.float :cpu,                     null:true
      t.float :memory,                  null:true
      t.float :hdd,                     null:true
      t.integer :hourly_cost,           null:false

      t.belongs_to :compute_site
    end

    add_foreign_key :atmosphere_virtual_machine_flavors,
                    :atmosphere_compute_sites,
                    column: 'compute_site_id'

    # Add backreference in virtual_machines
    change_table :atmosphere_virtual_machines do |t|
      t.belongs_to :virtual_machine_flavor
    end

  end
end
