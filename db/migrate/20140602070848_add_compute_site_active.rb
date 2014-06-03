class AddComputeSiteActive < ActiveRecord::Migration
  def change
    add_column :compute_sites, :active, :boolean, default: true
  end
end
