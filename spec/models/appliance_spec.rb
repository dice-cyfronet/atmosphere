# == Schema Information
#
# Table name: appliances
#
#  id                                  :integer          not null, primary key
#  appliance_set_id                    :integer          not null
#  appliance_type_id                   :integer          not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  appliance_configuration_instance_id :integer          not null
#

require 'spec_helper'

describe Appliance do

  expect_it { to belong_to :appliance_set }
  expect_it { to validate_presence_of :appliance_set }

  expect_it { to belong_to :appliance_type }
  expect_it { to validate_presence_of :appliance_type }

  expect_it { to belong_to :appliance_configuration_instance }
  expect_it { to validate_presence_of :appliance_configuration_instance }

  expect_it { to have_many(:http_mappings).dependent(:destroy) }

  pending 'should support development mode relations'
  pending 'should require zero or many VirtualMachines'
end
