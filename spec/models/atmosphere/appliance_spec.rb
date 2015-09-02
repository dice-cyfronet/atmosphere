require 'rails_helper'

describe Atmosphere::Appliance do
  it { should belong_to :appliance_set }
  it { should validate_presence_of :appliance_set }
  it { should validate_presence_of :state }
  it do
    should validate_inclusion_of(:state).
      in_array(%w(new satisfied unsatisfied))
  end

  it { should belong_to :appliance_type }
  it { should validate_presence_of :appliance_type }

  it { should belong_to :appliance_configuration_instance }
  it { should validate_presence_of :appliance_configuration_instance }

  it { should have_many(:http_mappings).dependent(:destroy) }

  it { should have_one(:dev_mode_property_set).dependent(:destroy) }
  it { should have_readonly_attribute :dev_mode_property_set }

  context 'optimization strategy validation' do
    it 'is valid if optimization strategy supports as of given type' do
      allow(Atmosphere::OptimizationStrategy::Default).
        to receive(:supports?).and_return true
      create(:appliance)
    end
    it 'raise an error if strategy does not support as of given type' do
      allow(Atmosphere::OptimizationStrategy::Default).
        to receive(:supports?).and_return false
      expect { create(:appliance) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'optimization strategy' do
    it 'default is used when optimization policy is not set' do
      expect(Atmosphere::Appliance.new.optimization_strategy.class).
        to eq Atmosphere::OptimizationStrategy::Default
    end

    it 'default is used when optimization policy specificies undefined class' do
      appl = Atmosphere::Appliance.new(optimization_policy: 'undefined')
      expect(appl.optimization_strategy.class).
        to eq Atmosphere::OptimizationStrategy::Default
    end

    context 'optimization policy defined for appliance set' do
      let(:as) { Atmosphere::ApplianceSet.new(optimization_policy: :manual) }
      it 'is used when appliance does not define optimization strategy' do
        appl = Atmosphere::Appliance.new(appliance_set: as)
        expect(appl.optimization_strategy.class).
          to eq Atmosphere::OptimizationStrategy::Manual
      end

      context 'policy defined for appliance' do
        it 'uses strategy defined in appl' do
          appl = Atmosphere::Appliance.new(
            appliance_set: as,
            optimization_policy: :default
          )
          expect(appl.optimization_strategy.class).
            to eq Atmosphere::OptimizationStrategy::Default
        end
      end
    end

    context 'policy defined only for appliance' do
      it 'uses policy defined in appl' do
        as = Atmosphere::ApplianceSet.new(optimization_policy: nil)
        appl = Atmosphere::Appliance.new(
          appliance_set: as,
          optimization_policy: :manual
        )
        expect(appl.optimization_strategy.class).
          to eq Atmosphere::OptimizationStrategy::Manual
      end
    end
  end

  context 'appliance configuration instances management' do
    let!(:appliance) { create(:appliance) }

    it 'removes configuration instance with the last Appliance using it' do
      expect { appliance.destroy }.
        to change { Atmosphere::ApplianceConfigurationInstance.count }.by(-1)
    end

    it 'config instance is not removed when other Appliance is using it' do
      config = appliance.appliance_configuration_instance
      create(:appliance, appliance_configuration_instance: config)

      expect { appliance.destroy }.
        to change { Atmosphere::ApplianceConfigurationInstance.count }.by(0)
    end
  end

  context 'development mode' do
    let(:appliance_type) { create(:appliance_type) }
    let(:dev_appliance_set) { create(:dev_appliance_set) }
    let(:workflow_appliance_set) { create(:workflow_appliance_set) }
    let(:portal_appliance_set) { create(:portal_appliance_set) }

    before do
      allow(Atmosphere::DevModePropertySet).
        to receive(:create_from).
        and_return(Atmosphere::DevModePropertySet.new(name: 'dev'))
    end

    context 'when development appliance set' do
      it 'creates dev mode property set' do
        appliance = create(:appliance,
                           appliance_type: appliance_type,
                           appliance_set: dev_appliance_set)

        expect(Atmosphere::DevModePropertySet).
          to have_received(:create_from).with(appliance_type).once
        expect(appliance.dev_mode_property_set).to_not be_nil
      end

      it 'saves dev mode property set' do
        expect do
          create(:appliance,
                 appliance_type: appliance_type,
                 appliance_set: dev_appliance_set)
        end.to change { Atmosphere::DevModePropertySet.count }.by(1)
      end

      it 'overwrite dev mode property set' do
        appliance = build(:appliance,
                          appliance_type: appliance_type,
                          appliance_set: dev_appliance_set)

        appliance.create_dev_mode_property_set(preference_memory: 123,
                                               preference_cpu: 2,
                                               preference_disk: 321)

        expect(appliance.dev_mode_property_set.preference_memory).to eq 123
        expect(appliance.dev_mode_property_set.preference_cpu).to eq 2
        expect(appliance.dev_mode_property_set.preference_disk).to eq 321
      end
    end

    context 'does not create dev mode property set' do
      it 'when workflow appliance set' do
        appliance = create(:appliance,
                           appliance_type: appliance_type,
                           appliance_set: workflow_appliance_set)

        expect(Atmosphere::DevModePropertySet).
          to_not have_received(:create_from)
        expect(appliance.dev_mode_property_set).to be_nil
      end

      it 'when portal appliance set' do
        appliance = create(:appliance,
                           appliance_type: appliance_type,
                           appliance_set: portal_appliance_set)

        expect(Atmosphere::DevModePropertySet).
          to_not have_received(:create_from)
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

  it 'is owned by a user' do
    user = build(:user)
    as = build(:appliance_set, user: user)
    appl = create(:appliance, appliance_set: as)

    expect(appl.owned_by?(user)).to be_truthy
  end

  it 'deletes linking table records but not tenants when destroyed' do
    t = create(:tenant)
    a = create(:appliance, tenants: [t])

    expect { a.destroy }.
      to change { Atmosphere::ApplianceTenant.count }.by(-1)
    expect(t).to_not be_nil
  end
end
