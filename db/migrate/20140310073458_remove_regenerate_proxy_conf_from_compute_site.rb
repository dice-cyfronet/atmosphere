class RemoveRegenerateProxyConfFromComputeSite < ActiveRecord::Migration
  def change
    remove_column :compute_sites, :regenerate_proxy_conf, :boolean
  end
end
