class ChangeZabbixHostIdToMonitoringIdInVirtualMachines < ActiveRecord::Migration
  
  def change
    change_table :virtual_machines do |t|
      t.rename :zabbix_host_id, :monitoring_id
    end
  end

end
