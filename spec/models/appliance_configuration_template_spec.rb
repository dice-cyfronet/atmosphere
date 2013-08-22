require 'spec_helper'

describe ApplianceConfigurationTemplate do
  expect_it { to validate_presence_of :name }
  expect_it { to validate_presence_of :appliance_type }
  expect_it { to belong_to :appliance_type }

  describe 'name uniques' do
    let(:appliance_type1) { create(:appliance_type) }
    let(:appliance_type2) { create(:appliance_type) }
    let(:ac_template) { create(:appliance_configuration_template, appliance_type: appliance_type1) }

    it 'allows 2 identical name when appliance types are different' do
      new_ac_template = build(:appliance_configuration_template, name: ac_template.name, appliance_type: appliance_type2)
      new_ac_template.save
      expect(new_ac_template).to be_valid
    end

    it 'does not allow 2 identical names for one appliance type' do
      new_ac_template = build(:appliance_configuration_template, name: ac_template.name, appliance_type: appliance_type1)
      new_ac_template.save
      expect(new_ac_template).to_not be_valid
    end
  end
end
