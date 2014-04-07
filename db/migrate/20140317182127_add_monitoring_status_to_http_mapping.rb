class AddMonitoringStatusToHttpMapping < ActiveRecord::Migration
  def change
    add_column :http_mappings, :monitoring_status, :string
  end
end
