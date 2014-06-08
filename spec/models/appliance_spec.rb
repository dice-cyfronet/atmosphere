# == Schema Information
#
# Table name: appliances
#
#  id                                  :integer          not null, primary key
#  appliance_set_id                    :integer          not null
#  appliance_type_id                   :integer          not null
#  user_key_id                         :integer
#  appliance_configuration_instance_id :integer          not null
#  state                               :string(255)      default("new"), not null
#  name                                :string(255)
#  created_at                          :datetime
#  updated_at                          :datetime
#  fund_id                             :integer
#  last_billing                        :datetime
#  state_explanation                   :string(255)
#  amount_billed                       :integer          default(0), not null
#  billing_state                       :string(255)      default("prepaid"), not null
#  prepaid_until                       :datetime         not null
#  description                         :text
#

require 'spec_helper'

describe Appliance do

  let(:optimizer) {double}

  expect_it { to belong_to :appliance_set }
  expect_it { to validate_presence_of :appliance_set }
  expect_it { to validate_presence_of :state }
  expect_it { to ensure_inclusion_of(:state).in_array(%w(new satisfied unsatisfied))}

  expect_it { to belong_to :appliance_type }
  expect_it { to validate_presence_of :appliance_type }

  expect_it { to belong_to :appliance_configuration_instance }
  expect_it { to validate_presence_of :appliance_configuration_instance }

  expect_it { to have_many(:http_mappings).dependent(:destroy) }

  expect_it { to have_one(:dev_mode_property_set).dependent(:destroy) }
  expect_it { to have_readonly_attribute :dev_mode_property_set }

  context 'appliance configuration instances management' do
    before do
      Optimizer.stub(:instance).and_return(optimizer)
      expect(optimizer).to receive(:run).twice
    end
    let!(:appliance) { create(:appliance) }

    it 'removes appliance configuratoin instance when last Appliance using it' do
      expect {
        appliance.destroy
      }.to change { ApplianceConfigurationInstance.count }.by(-1)
    end

    it 'does not remove appliance configuration instance when other Appliance is using it' do
      expect(optimizer).to receive(:run).once
      create(:appliance, appliance_configuration_instance: appliance.appliance_configuration_instance)
      expect {
        appliance.destroy
      }.to change { ApplianceConfigurationInstance.count }.by(0)
    end
  end

  context 'development mode' do
    let(:appliance_type) { create(:appliance_type) }
    let(:dev_appliance_set) { create(:dev_appliance_set) }
    let(:workflow_appliance_set) { create(:workflow_appliance_set) }
    let(:portal_appliance_set) { create(:portal_appliance_set) }


    before {
      DevModePropertySet.stub(:create_from).and_return(DevModePropertySet.new(name: 'dev'))
    }

    context 'when development appliance set' do
      it 'creates dev mode property set' do
        appliance = create(:appliance, appliance_type: appliance_type, appliance_set: dev_appliance_set)

        expect(DevModePropertySet).to have_received(:create_from).with(appliance_type).once
        expect(appliance.dev_mode_property_set).to_not be_nil
      end

      it 'saves dev mode property set' do
        expect {
          create(:appliance, appliance_type: appliance_type, appliance_set: dev_appliance_set)
        }.to change { DevModePropertySet.count }.by(1)
      end

      it 'overwrite dev mode property set' do
        appliance = build(:appliance, appliance_type: appliance_type, appliance_set: dev_appliance_set)

        appliance.create_dev_mode_property_set(preference_memory: 123, preference_cpu: 2, preference_disk: 321)

        expect(appliance.dev_mode_property_set.preference_memory).to eq 123
        expect(appliance.dev_mode_property_set.preference_cpu).to eq 2
        expect(appliance.dev_mode_property_set.preference_disk).to eq 321
      end
    end

    context 'does not create dev mode property set' do
      it 'when workflow appliance set' do
        appliance = create(:appliance, appliance_type: appliance_type, appliance_set: workflow_appliance_set)

        expect(DevModePropertySet).to_not have_received(:create_from)
        expect(appliance.dev_mode_property_set).to be_nil
      end

      it 'when portal appliance set' do
        appliance = create(:appliance, appliance_type: appliance_type, appliance_set: portal_appliance_set)

        expect(DevModePropertySet).to_not have_received(:create_from)
        expect(appliance.dev_mode_property_set).to be_nil
      end
    end
  end

  context '#user_data' do
    let(:appl) do
      build(:appliance).tap do |appl|
        appl.appliance_configuration_instance =
          build(:appliance_configuration_instance, payload: 'user_data')
      end
    end

    it 'returns user data from configuration instance' do
      expect(appl.user_data).to eq 'user_data'
    end
  end
end
