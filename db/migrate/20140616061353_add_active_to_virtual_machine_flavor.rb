class AddActiveToVirtualMachineFlavor < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_virtual_machine_flavors,
               :active, :boolean, default: true
  end
end
