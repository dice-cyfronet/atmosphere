class AddComputeSiteIdToTenants < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_tenants, :site_id, :string
  end
end
