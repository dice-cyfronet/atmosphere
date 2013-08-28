# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id                                  :integer          not null, primary key
#  payload                             :text
#  appliance_configuration_template_id :integer          not null
#  created_at                          :datetime
#  updated_at                          :datetime
#

require 'spec_helper'

describe ApplianceConfigurationInstance do
  expect_it { to have_many(:appliances) }
  expect_it { to belong_to(:appliance_configuration_template) }
end
