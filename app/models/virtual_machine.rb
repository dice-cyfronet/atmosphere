class VirtualMachine < ActiveRecord::Base
  has_many :appliances
  has_many :saved_templates, class_name: 'VirtualMachineTemplate'
  belongs_to :source_template, class_name: 'VirtualMachineTemplate', foreign_key: 'virtual_machine_template_id'
end
