class MonitoringStatusDefaultToHttpMapping < ActiveRecord::Migration
  def change
    change_column :http_mappings, :monitoring_status, :string, default: "NEW"
  end
end
