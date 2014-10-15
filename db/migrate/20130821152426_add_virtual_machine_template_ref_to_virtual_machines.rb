class AddVirtualMachineTemplateRefToVirtualMachines < ActiveRecord::Migration
  def change
    add_reference :atmosphere_virtual_machines,
                  :virtual_machine_template

    add_index :atmosphere_virtual_machines,
              :virtual_machine_template_id,
              name: 'atmo_vm_vmt_ix'

    add_foreign_key :atmosphere_virtual_machines,
                    :atmosphere_virtual_machine_templates,
                    column: 'virtual_machine_template_id',
                    name: 'atmo_vm_vmt_fk'
  end
end
