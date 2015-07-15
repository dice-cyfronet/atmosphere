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

require 'rails_helper'

describe Atmosphere::Appliance do

  let(:optimizer) {double}

  it { should belong_to :appliance_set }
  it { should validate_presence_of :appliance_set }
  it { should validate_presence_of :state }
  it { should validate_inclusion_of(:state).in_array(%w(new satisfied unsatisfied))}

  it { should belong_to :appliance_type }
  it { should validate_presence_of :appliance_type }

  it { should belong_to :appliance_configuration_instance }
  it { should validate_presence_of :appliance_configuration_instance }

  it { should have_many(:http_mappings).dependent(:destroy) }

  it { should have_one(:dev_mode_property_set).dependent(:destroy) }
  it { should have_readonly_attribute :dev_mode_property_set }

  context 'optimization strategy' do
    it 'returns default optimization strategy if optimization policy is not defined' do
      expect(Atmosphere::Appliance.new.optimization_strategy.class).to eq Atmosphere::OptimizationStrategy::Default
    end

    context 'optimization policy defined for appliance set' do
      context 'policy not defined for appliance' do
        it 'returns optimization strategy that is defined for appliance set' do
          as = Atmosphere::ApplianceSet.new(optimization_policy: :manual)
          appl = Atmosphere::Appliance.new(appliance_set: as)
          expect(appl.optimization_strategy.class).to eq Atmosphere::OptimizationStrategy::Manual
        end
      end

      context 'policy defined for appliance' do
        it 'returns optimization strategy that is defined for appliance set if strategy is not defined directly for appliance' do
          pending 'someone left this spec empty - setting it as pending'
          fail
        end
      end
    end

    context 'policy defined only for appliance' do

    end
  end

  context 'appliance configuration instances management' do
    before do
      allow(Atmosphere::Optimizer).to receive(:instance).and_return(optimizer)
      allow(optimizer).to receive(:run)
    end
    let!(:appliance) { create(:appliance) }

    it 'removes configuration instance with the last Appliance using it' do
      expect {
        appliance.destroy
      }.to change { Atmosphere::ApplianceConfigurationInstance.count }.by(-1)
    end

    it 'does not remove appliance configuration instance when other Appliance is using it' do
      expect(optimizer).to receive(:run).once
      create(:appliance, appliance_configuration_instance: appliance.appliance_configuration_instance)
      expect {
        appliance.destroy
      }.to change { Atmosphere::ApplianceConfigurationInstance.count }.by(0)
    end
  end

  context 'development mode' do
    let(:appliance_type) { create(:appliance_type) }
    let(:dev_appliance_set) { create(:dev_appliance_set) }
    let(:workflow_appliance_set) { create(:workflow_appliance_set) }
    let(:portal_appliance_set) { create(:portal_appliance_set) }


    before {
      allow(Atmosphere::DevModePropertySet).to receive(:create_from)
        .and_return(Atmosphere::DevModePropertySet.new(name: 'dev'))
    }

    context 'when development appliance set' do
      it 'creates dev mode property set' do
        appliance = create(:appliance, appliance_type: appliance_type, appliance_set: dev_appliance_set)

        expect(Atmosphere::DevModePropertySet).to have_received(:create_from).with(appliance_type).once
        expect(appliance.dev_mode_property_set).to_not be_nil
      end

      it 'saves dev mode property set' do
        expect {
          create(:appliance, appliance_type: appliance_type, appliance_set: dev_appliance_set)
        }.to change { Atmosphere::DevModePropertySet.count }.by(1)
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

        expect(Atmosphere::DevModePropertySet).to_not have_received(:create_from)
        expect(appliance.dev_mode_property_set).to be_nil
      end

      it 'when portal appliance set' do
        appliance = create(:appliance, appliance_type: appliance_type, appliance_set: portal_appliance_set)

        expect(Atmosphere::DevModePropertySet).to_not have_received(:create_from)
        expect(appliance.dev_mode_property_set).to be_nil
      end
    end
  end

  context 'when instantiated' do
    let(:appliance_type) { create(:appliance_type) }
    let(:appliance_set) { create(:appliance_set) }
    let(:appliance) do
      create(:appliance,
              appliance_set: appliance_set,
              appliance_type: appliance_type,
              fund: nil)
    end

    it 'does not change fund when externally assigned' do
      funded_appliance = create(:appliance)
      expect(funded_appliance.fund).not_to eq appliance.send(:default_fund)
    end

    it 'gets default fund from its user if no fund is set' do
      expect(appliance.fund).to eq appliance.send(:default_fund)
    end

    it 'prefers default fund if it supports relevant tenant' do
      default_t = create(:openstack_with_flavors,
                          funds: [appliance_set.user.default_fund])
      funded_t = create(:openstack_with_flavors, funds: [create(:fund)])
      appliance_set.user.funds << funded_t.funds.first
      create(:virtual_machine_template,
             appliance_type: appliance_type,
             tenants: [default_t])
      create(:virtual_machine_template,
             appliance_type: appliance_type,
             tenants: [funded_t])
      supported_appliance_types = Atmosphere::Tenant.all.map do |t|
        t.virtual_machine_templates.map(&:appliance_type)
      end
      expect(supported_appliance_types).to all(include(appliance_type))
      expect(appliance.fund).not_to eq funded_t.funds.first
      expect(appliance.fund).to eq appliance.send(:default_fund)
    end

    it 'chooses one of user funds that support relevant tenant' do
      create(:openstack_with_flavors, funds: [appliance_set.user.default_fund])
      funded_t = create(:openstack_with_flavors, funds: [create(:fund)])
      appliance_set.user.funds << funded_t.funds.first
      create(:virtual_machine_template,
             appliance_type: appliance_type,
             tenants: [funded_t])
      expect(appliance.fund).to eq funded_t.funds.first
      expect(appliance.fund).not_to eq appliance.send(:default_fund)
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

  it 'is owned by a user' do
    user = build(:user)
    as = build(:appliance_set, user: user)
    appl = create(:appliance, appliance_set: as)

    expect(appl.owned_by?(user)).to be_truthy
  end

  context '#default_fund' do
    let(:appliance) { create(:appliance) }

    it 'provides appliance user default fund' do
      expect(appliance.send(:default_fund)).
        to eq appliance.appliance_set.user.default_fund
    end

    it 'does not crash when no data is present' do
      appliance.appliance_set.user = nil
      expect(appliance.send(:default_fund)).to eq nil
    end
  end

  context '#clean_up_on_delete' do
    it 'deletes linking table records but not tenants when destroyed' do
      t = create(:tenant)
      a = create(:appliance, tenants: [t])

      expect { a.destroy }.
        to change { Atmosphere::ApplianceTenant.count }.by(-1)
      expect(t).to_not be_nil
    end
  end

end
