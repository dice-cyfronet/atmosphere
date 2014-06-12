class AddUpdatedAtSiteToVirtualMachine < ActiveRecord::Migration
  def change
    add_column :virtual_machines, :updated_at_site, :datetime
  end
end
