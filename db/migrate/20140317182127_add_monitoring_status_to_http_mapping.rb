class AddMonitoringStatusToHttpMapping < ActiveRecord::Migration
  def change
    add_column :atmosphere_http_mappings, :monitoring_status, :string
  end
end
