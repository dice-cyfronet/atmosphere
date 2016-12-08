class AddNicProviderConfigToComputeSite < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_compute_sites, :nic_provider_config, :text
  end
end
