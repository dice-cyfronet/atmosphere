class AddComputeSiteIdToTenants < ActiveRecord::Migration
  def change
    add_column :atmosphere_tenants, :site_id, :string
  end
end
