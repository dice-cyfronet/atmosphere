# == Schema Information
#
# Table name: virtual_machines
#
#  id                          :integer          not null, primary key
#  id_at_site                  :string(255)      not null
#  name                        :string(255)      not null
#  state                       :string(255)      not null
#  ip                          :string(255)
#  compute_site_id             :integer          not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#

class VirtualMachine < ActiveRecord::Base
  has_many :saved_templates, class_name: 'VirtualMachineTemplate'
  has_many :port_mappings, dependent: :destroy
  belongs_to :source_template, class_name: 'VirtualMachineTemplate', foreign_key: 'virtual_machine_template_id'
  belongs_to :compute_site
  has_and_belongs_to_many :appliances
  validates_presence_of :id_at_site, :name, :state, :compute_site_id
  validates_uniqueness_of :id_at_site, :scope => :compute_site_id
end
