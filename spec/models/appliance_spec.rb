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

  expect_it { to have_one(:dev_mode_property_set).dependent(:destroy) }

  describe 'appliance configuration instances management' do
    let!(:appliance) { create(:appliance) }

    it 'removes appliance configuratoin instance when last Appliance using it' do
      expect {
        appliance.destroy
      }.to change { ApplianceConfigurationInstance.count }.by(-1)
    end

    it 'does not remove appliance configuration instance when other Appliance is using it' do
      create(:appliance, appliance_configuration_instance: appliance.appliance_configuration_instance)
      expect {
        appliance.destroy
      }.to change { ApplianceConfigurationInstance.count }.by(0)
    end
  end

  pending 'should support development mode relations'
  pending 'should require zero or many VirtualMachines'
end
