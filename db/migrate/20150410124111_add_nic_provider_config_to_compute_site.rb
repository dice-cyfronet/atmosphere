class AddNicProviderConfigToComputeSite < ActiveRecord::Migration
  def change
    add_column :atmosphere_compute_sites, :nic_provider_config, :text
  end
end
