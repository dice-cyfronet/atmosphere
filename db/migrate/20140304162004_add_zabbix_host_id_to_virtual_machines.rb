class AddZabbixHostIdToVirtualMachines < ActiveRecord::Migration
  def change
    add_column :virtual_machines, :zabbix_host_id, :integer
  end
end
