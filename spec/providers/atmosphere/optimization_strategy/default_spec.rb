require 'rails_helper'

describe Atmosphere::OptimizationStrategy::Default do

  before do
    Fog.mock!
  end

  it 'supports dev mode appliance set' do
    as = build(:dev_appliance_set)
    expect(Atmosphere::OptimizationStrategy::Default.supports?(as)).to be_truthy
  end

  it 'supports portal appliance set' do
    as = build(:portal_appliance_set)
    expect(Atmosphere::OptimizationStrategy::Default.supports?(as)).to be_truthy
  end

  it 'supports workflow appliance set' do
    as = build(:workflow_appliance_set)
    expect(Atmosphere::OptimizationStrategy::Default.supports?(as)).to be_truthy
  end

  context '#can_reuse_vm?' do

    it 'reuses shared VMs in prod mode' do
      appl = appliance(development: false, shared: true)
      subject = Atmosphere::OptimizationStrategy::Default.new(appl)

      expect(subject.can_reuse_vm?).to be_truthy
    end

    it 'does not reuse VM in dev mode' do
      appl = appliance(development: true, shared: true)
      subject = Atmosphere::OptimizationStrategy::Default.new(appl)

      expect(subject.can_reuse_vm?).to be_falsy
    end

    it 'does not reuse not shareable VMs' do
      appl = appliance(development: false, shared: false)
      subject = Atmosphere::OptimizationStrategy::Default.new(appl)

      expect(subject.can_reuse_vm?).to be_falsy
    end
  end

  def appliance(options)
    double(
      development?: options[:development],
      appliance_type: double(shared: options[:shared])
    )
  end

  context 'new appliance created' do
    let(:wf) { create(:workflow_appliance_set) }
    let(:openstack) { create(:openstack_with_flavors, funds: [fund]) }
    let(:fund) { create(:fund) }
    let(:u) { create(:user, funds: [fund]) }
    let(:aset) { create(:appliance_set, user: u) }
    let(:shareable_appl_type) { create(:shareable_appliance_type) }
    let(:not_shareable_appl_type) { create(:not_shareable_appliance_type) }

    before do
      create(:virtual_machine_template,
             appliance_type: shareable_appl_type,
             tenants: [openstack])
    end

    context 'development mode' do

      let(:dev_appliance_set) { create(:dev_appliance_set) }
      let(:config_inst) { create(:appliance_configuration_instance) }
      it 'does not allow to reuse vm for dev appliance' do
        appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
        appl2 = Atmosphere::Appliance.new(appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
        subject = Atmosphere::OptimizationStrategy::Default.new(appl2)
        expect(subject.can_reuse_vm?).to be_falsy
      end

      it 'does not reuse available vm if it is in dev mode' do
        appl1 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
        appl2 = Atmosphere::Appliance.new(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
        subject = Atmosphere::OptimizationStrategy::Default.new(appl2)
        expect(subject.vm_to_reuse).to be nil
      end
    end

    it 'scopes potential VMs to ones on tenants funded by chosen fund' do
      nonfunded_t = create(:openstack_with_flavors, funds: [create(:fund)])
      a = create(:appliance,
                 appliance_set: aset,
                 appliance_type: not_shareable_appl_type,
                 fund: fund,
                 tenants: Atmosphere::Tenant.all)
      create(:virtual_machine_template,
             appliance_type: a.appliance_type,
             tenants: [nonfunded_t])
      create(:virtual_machine_template,
             appliance_type: a.appliance_type,
             tenants: [openstack])
      supported_appliance_types = Atmosphere::Tenant.all.map do |t|
        t.virtual_machine_templates.map(&:appliance_type)
      end
      expect(supported_appliance_types).to all(include(a.appliance_type))
      default_strategy = Atmosphere::OptimizationStrategy::Default.new(a)
      vm_candidates = default_strategy.send(:vmt_candidates)
      expect(vm_candidates.count).to eq 1
      expect(vm_candidates.first.tenants.first).to eq openstack
    end
  end
end
