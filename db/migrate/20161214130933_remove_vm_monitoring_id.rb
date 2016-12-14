class RemoveVmMonitoringId < ActiveRecord::Migration[5.0]
  def change
    remove_column :atmosphere_virtual_machines, :monitoring_id
  end
end
