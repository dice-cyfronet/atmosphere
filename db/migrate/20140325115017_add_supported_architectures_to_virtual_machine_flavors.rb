class AddSupportedArchitecturesToVirtualMachineFlavors < ActiveRecord::Migration
  def change
    add_column :atmosphere_virtual_machine_flavors,
               :supported_architectures, :string, default: 'x86_64'
  end
end
