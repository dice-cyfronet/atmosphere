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

require 'rails_helper'

describe Atmosphere::ApplianceConfigurationInstance do
  it { should have_many(:appliances) }
  it { should belong_to(:appliance_configuration_template) }

  context '::get' do
    let(:act) { create(:appliance_configuration_template, payload: 'a #{param}') }

    context 'when no duplication exists' do
      it 'creates new appliance configuration instance' do
        instance = Atmosphere::ApplianceConfigurationInstance.get(act, {'param' => 'a' })

        expect(instance.new_record?).to be_truthy
      end
    end

    context 'when duplication exists' do
      before do
        create(:appliance_configuration_instance, payload: 'a a', appliance_configuration_template: act)
      end

      it 'reuses existing instance' do
        instance = Atmosphere::ApplianceConfigurationInstance.get(act, {'param' => 'a' })

        expect(instance.new_record?).to be_falsy
      end
    end
  end
end
