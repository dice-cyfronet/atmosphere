class VirtualMachineTemplate < ActiveRecord::Base
  belongs_to :source_vm, class_name: 'VirtualMachine', foreign_key: 'virtual_machine_id'
  has_many :instances, class_name: 'VirtualMachine'
end
