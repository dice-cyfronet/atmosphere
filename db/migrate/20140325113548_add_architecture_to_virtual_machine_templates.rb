class AddArchitectureToVirtualMachineTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_virtual_machine_templates,
               :architecture, :string, default: 'x86_64'
  end
end
