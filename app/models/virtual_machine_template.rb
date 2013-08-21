class VirtualMachineTemplate < ActiveRecord::Base
  belongs_to :source_vm, :class_name: 'VirtualMachine', :foreign_key: 'virtual_machine_id'
end
