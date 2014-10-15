class AddArchitectureToVirtualMachineTemplates < ActiveRecord::Migration
  def change
    add_column :atmosphere_virtual_machine_templates,
               :architecture, :string, default: 'x86_64'
  end
end
