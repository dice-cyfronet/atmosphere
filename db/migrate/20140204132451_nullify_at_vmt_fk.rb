class NullifyAtVmtFk < ActiveRecord::Migration
  def change
    remove_foreign_key :virtual_machine_templates, :appliance_types
    add_foreign_key :virtual_machine_templates, :appliance_types, dependent: :nullify
  end
end
