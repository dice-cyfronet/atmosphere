class VirtualMachine < ActiveRecord::Base
  has_many :saved_templates, :class_name: 'VirtualMachineTemplate'
end
