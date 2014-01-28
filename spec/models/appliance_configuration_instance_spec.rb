# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id                                  :integer          not null, primary key
#  payload                             :text
#  appliance_configuration_template_id :integer
#  created_at                          :datetime
#  updated_at                          :datetime
#

require 'spec_helper'

describe ApplianceConfigurationInstance do
  expect_it { to have_many(:appliances) }
  expect_it { to belong_to(:appliance_configuration_template) }

  context '::get' do
    let(:act) { create(:appliance_configuration_template, payload: 'a #{param}') }

    context 'when no duplication exists' do
      it 'creates new appliance configuration instance' do
        instance = ApplianceConfigurationInstance.get(act, {'param' => 'a' })

        expect(instance.new_record?).to be_true
      end
    end

    context 'when duplication exists' do
      before do
        create(:appliance_configuration_instance, payload: 'a a', appliance_configuration_template: act)
      end

      it 'reuses existing instance' do
        instance = ApplianceConfigurationInstance.get(act, {'param' => 'a' })

        expect(instance.new_record?).to be_false
      end
    end
  end
end
