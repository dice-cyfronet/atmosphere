class AddIdAtSiteToVirtualMachineFlavors < ActiveRecord::Migration[4.2]
  def change
    change_table :atmosphere_virtual_machine_flavors do |t|
      t.column :id_at_site, :string, null: true # Must be true to allow retroactive updates on existing data model
    end
  end
end
