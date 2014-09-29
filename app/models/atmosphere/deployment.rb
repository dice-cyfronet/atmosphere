# == Schema Information
#
# Table name: deployments
#
#  id                 :integer          not null, primary key
#  virtual_machine_id :integer
#  appliance_id       :integer
#

# Deployments provide a m:n link between appliances and virtual machines.
class Deployment < ActiveRecord::Base
  belongs_to :appliance
  belongs_to :virtual_machine
end
