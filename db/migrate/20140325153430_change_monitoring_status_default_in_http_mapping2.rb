class ChangeMonitoringStatusDefaultInHttpMapping2 < ActiveRecord::Migration
  def change
    change_column :atmosphere_http_mappings,
                  :monitoring_status, :string, default: :pending
  end
end
