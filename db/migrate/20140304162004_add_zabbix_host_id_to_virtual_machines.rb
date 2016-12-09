class AddZabbixHostIdToVirtualMachines < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_virtual_machines, :zabbix_host_id, :integer
  end
end
