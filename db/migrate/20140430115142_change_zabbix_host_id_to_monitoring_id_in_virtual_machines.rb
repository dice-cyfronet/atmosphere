class ChangeZabbixHostIdToMonitoringIdInVirtualMachines < ActiveRecord::Migration[4.2]

  def up
    change_table :atmosphere_virtual_machines do |t|
      t.rename :zabbix_host_id, :monitoring_id
    end
  end

  def down
    change_table :atmosphere_virtual_machines do |t|
      t.rename :monitoring_id, :zabbix_host_id
    end
  end
end
