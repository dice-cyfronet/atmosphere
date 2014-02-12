# == Schema Information
#
# Table name: virtual_machine_flavors
#
#  id              :integer          not null, primary key
#  flavor_name     :string(255)      not null
#  cpu             :float
#  memory          :float
#  hdd             :float
#  hourly_cost     :integer          not null
#  compute_site_id :integer
#

# VirtualMachineFlavor
# Added by PN on 2014-01-14
# This class stores information on the VM flavors available at each compute site registered with AIR
# For each flavor, the associated hourly cost is defined.

class VirtualMachineFlavor < ActiveRecord::Base

  belongs_to :compute_site
  has_many :virtual_machines

  validates_presence_of :flavor_name
  validates_uniqueness_of :flavor_name, scope: :compute_site
  validates_numericality_of :cpu, greater_than_or_equal_to: 0
  validates_numericality_of :memory, greater_than_or_equal_to: 0
  validates_numericality_of :hdd, greater_than_or_equal_to: 0
  validates_numericality_of :hourly_cost, greater_than_or_equal_to: 0

end
