class AddWranglerConfigToComputeSites < ActiveRecord::Migration
  def change
    add_column :atmosphere_compute_sites, :wrangler_url, :string
    add_column :atmosphere_compute_sites, :wrangler_username, :string
    add_column :atmosphere_compute_sites, :wrangler_password, :string
  end
end
