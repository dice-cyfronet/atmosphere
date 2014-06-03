class ChangeZabbixHostIdToMonitoringIdInVirtualMachines < ActiveRecord::Migration
  
  def up
    change_table :virtual_machines do |t|
      t.rename :zabbix_host_id, :monitoring_id
    end
  end

  def down
    change_table :virtual_machines do |t|
      t.rename :monitoring_id, :zabbix_host_id
    end
  end
end
