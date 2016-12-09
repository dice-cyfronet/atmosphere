class MonitoringStatusDefaultToHttpMapping < ActiveRecord::Migration[4.2]
  def change
    change_column :atmosphere_http_mappings,
                  :monitoring_status, :string, default: "new"
  end
end
