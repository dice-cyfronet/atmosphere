class AddIdAtSiteToVirtualMachineFlavors < ActiveRecord::Migration
  def change
    change_table :virtual_machine_flavors do |t|
      t.column :id_at_site, :string, null: true # Must be true to allow retroactive updates on existing data model
    end
  end
end
