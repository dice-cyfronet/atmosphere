class AddZabbixHostIdToVirtualMachines < ActiveRecord::Migration
  def change
    add_column :atmosphere_virtual_machines, :zabbix_host_id, :integer
  end
end
