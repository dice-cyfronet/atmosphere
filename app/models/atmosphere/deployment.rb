# == Schema Information
#
# Table name: deployments
#
#  id                 :integer          not null, primary key
#  virtual_machine_id :integer
#  appliance_id       :integer
#

# Deployments provide a m:n link between appliances and virtual machines.
module Atmosphere
  class Deployment < ActiveRecord::Base
    self.table_name = 'deployments'

    belongs_to :appliance,
      class_name: 'Atmosphere::Appliance'

    belongs_to :virtual_machine,
      class_name: 'Atmosphere::VirtualMachine'
  end
end