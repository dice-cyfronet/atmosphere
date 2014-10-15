class AddComputeSiteActive < ActiveRecord::Migration
  def change
    add_column :atmosphere_compute_sites, :active, :boolean, default: true
  end
end
