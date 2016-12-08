class AddComputeSiteActive < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_compute_sites, :active, :boolean, default: true
  end
end
