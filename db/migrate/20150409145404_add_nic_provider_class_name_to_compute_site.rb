class AddNicProviderClassNameToComputeSite < ActiveRecord::Migration
  def change
    add_column :atmosphere_compute_sites, :nic_provider_class_name, :string
  end
end
