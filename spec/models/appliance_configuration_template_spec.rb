# == Schema Information
#
# Table name: appliance_configuration_templates
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  payload           :text
#  appliance_type_id :integer          not null
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe ApplianceConfigurationTemplate do
  expect_it { to validate_presence_of :name }
  expect_it { to validate_presence_of :appliance_type }
  expect_it { to belong_to :appliance_type }
  expect_it { to have_many(:appliance_configuration_instances).dependent(:nullify) }

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

  describe '#parameters' do
    let(:dynamic_ac_template) { create(:appliance_configuration_template, payload: 'dynamic #{a} #{b} #{c}') }
    let(:static_ac_template) { create(:appliance_configuration_template, payload: 'static') }
    let(:template_with_mi_ticket) { create(:appliance_configuration_template, payload: 'dynamic #{a} #{' + "#{Air.config.mi_authentication_key}}") }

    it 'returns parameters for dynamic configuration' do
      expect(dynamic_ac_template.parameters).to eq ['a', 'b', 'c']
    end

    it 'remote mi_ticket from params list' do
      expect(template_with_mi_ticket.parameters).to eq ['a']
    end

    it 'returns empty table for static configuration' do
      expect(static_ac_template.parameters).to eq []
    end
  end
end
