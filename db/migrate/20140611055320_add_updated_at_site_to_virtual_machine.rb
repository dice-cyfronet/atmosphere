class AddUpdatedAtSiteToVirtualMachine < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_virtual_machines, :updated_at_site, :datetime
  end
end
