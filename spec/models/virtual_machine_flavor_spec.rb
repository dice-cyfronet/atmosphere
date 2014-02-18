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

require 'spec_helper'

describe VirtualMachineFlavor do
  pending "add some examples to (or delete) #{__FILE__}"
end
