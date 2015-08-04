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

  context 'optimization strategy' do
    it 'default is used when optimization policy is not set' do
      expect(Atmosphere::Appliance.new.optimization_strategy.class).
        to eq Atmosphere::OptimizationStrategy::Default
    end

    context 'optimization policy defined for appliance set' do
      it 'is used when appliance does not define optimization strategy' do
        as = Atmosphere::ApplianceSet.new(optimization_policy: :manual)
        appl = Atmosphere::Appliance.new(appliance_set: as)
        expect(appl.optimization_strategy.class).
          to eq Atmosphere::OptimizationStrategy::Manual
      end

      context 'policy defined for appliance' do
        it 'uses AS strategy when not defined in appliance' do
          pending 'someone left this spec empty - setting it as pending'
          fail
        end
      end
    end

    context 'policy defined only for appliance' do
      pending
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

  context 'when instantiated' do
    let!(:appliance_type) { create(:appliance_type) }
    let!(:appliance_set) { create(:appliance_set) }
    let!(:appliance) do
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

  context '#assign_fund' do
    it 'does not assign a fund which is incompatible with selected tenants' do
      f1 = create(:fund)
      f2 = create(:fund)
      t1 = create(:tenant, funds: [f1])
      t2 = create(:tenant, funds: [f2])
      u = create(:user, funds: [f1, f2])
      vmt = create(:virtual_machine_template, tenants: [t1, t2])
      at = create(:appliance_type, virtual_machine_templates: [vmt])
      as = create(:appliance_set, user: u)

      t1_a = create(:appliance, appliance_set: as, appliance_type: at,
                                fund: nil, tenants: [t1])
      t2_a = create(:appliance, appliance_set: as, appliance_type: at,
                                fund: nil, tenants: [t2])

      expect(t1_a.fund).to eq f1
      expect(t2_a.fund).to eq f2
    end
  end

  it 'deletes linking table records but not tenants when destroyed' do
    t = create(:tenant)
    a = create(:appliance, tenants: [t])

    expect { a.destroy }.
      to change { Atmosphere::ApplianceTenant.count }.by(-1)
    expect(t).to_not be_nil
  end
end
