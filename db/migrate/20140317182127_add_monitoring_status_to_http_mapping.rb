class AddMonitoringStatusToHttpMapping < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_http_mappings, :monitoring_status, :string
  end
end
