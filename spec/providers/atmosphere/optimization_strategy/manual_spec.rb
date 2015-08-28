require 'rails_helper'

describe Atmosphere::OptimizationStrategy::Manual do

  before do
    Fog.mock!
    allow(Atmosphere::Optimizer.instance).to receive(:run)
  end

  let!(:fund) { create(:fund) }
  let!(:user) { create(:user, funds: [fund]) }
  let(:t) { create(:tenant, active: true, funds: [fund]) }
  let(:at) { create(:filled_appliance_type, visible_to: 'all', preference_disk: 0) }
  let!(:tmpl) { create(:virtual_machine_template, appliance_type: at, tenants: [t]) }
  let!(:fl1) { create(:virtual_machine_flavor, cpu: 1, memory: 512, tenant: t, active: true) }
  let!(:fl2) { create(:virtual_machine_flavor, cpu: 2, memory: 1024, tenant: t, active: true) }
  let(:cfg_tmpl) { create(:appliance_configuration_template, appliance_type: at)}
  let(:as) { create(:appliance_set, user: user)}
  let(:not_shareable_appl_type) { create(:not_shareable_appliance_type) }

  it 'return templates and flavors for each defined vm in opt policy params' do

    fl1.set_hourly_cost_for(at.os_family, 5)
    fl2.set_hourly_cost_for(at.os_family, 10)

    fl1.reload
    fl2.reload

    vms = [
      { 'cpu' => 1, 'mem' => 512, 'tenant_ids' => [t.id] },
      { 'cpu' => 2, 'mem' => 1024, 'tenant_ids' => [t.id] }
    ]
    created_appl_params = ActionController::Parameters.new(
      appliance_set_id: as.id,
      configuration_template_id: cfg_tmpl.id,
      vms: vms
    )
    creator = Atmosphere::ApplianceCreator.new(created_appl_params, 'dummy-token')
    appl = creator.build
    appl.fund = fund
    appl.save!

    manual_policy = Atmosphere::OptimizationStrategy::Manual.new(appl)

    tmpls_and_flavors_and_tenants = manual_policy.new_vms_tmpls_and_flavors_and_tenants

    expect(tmpls_and_flavors_and_tenants.size).to eq 2
    expect(tmpls_and_flavors_and_tenants[0][:template]).to eq tmpl
    expect(tmpls_and_flavors_and_tenants[0][:flavor]).to eq fl1
    expect(tmpls_and_flavors_and_tenants[0][:tenant]).to eq t
    expect(tmpls_and_flavors_and_tenants[1][:template]).to eq tmpl
    expect(tmpls_and_flavors_and_tenants[1][:flavor]).to eq fl2
    expect(tmpls_and_flavors_and_tenants[1][:tenant]).to eq t
  end

  context '#vms_to_start' do
    it 'returns n vms to start' do
      vm = create(:virtual_machine, state: :active, ip: '10.10.10.10')
      appl = create(:appliance, virtual_machines: [vm])
      strategy = described_class.new(appl)

      vms_to_start = strategy.vms_to_start(2)

      expect(vms_to_start.size).to eq 2
    end
  end


  it 'scopes potential VMs to ones on tenants funded by chosen fund' do
    nonfunded_t = create(:openstack_with_flavors, funds: [create(:fund)])
    a = create(:appliance,
               appliance_set: as,
               appliance_type: not_shareable_appl_type,
               fund: fund,
               tenants: Atmosphere::Tenant.all)
    create(:virtual_machine_template,
           appliance_type: a.appliance_type,
           tenants: [nonfunded_t])
    create(:virtual_machine_template,
           appliance_type: a.appliance_type,
           tenants: [t])
    supported_appliance_types = Atmosphere::Tenant.all.map do |t|
      t.virtual_machine_templates.map(&:appliance_type)
    end
    expect(supported_appliance_types).to all(include(a.appliance_type))
    manual_strategy = Atmosphere::OptimizationStrategy::Manual.new(a)
    vm_candidates = manual_strategy.send(:vmt_candidates)
    expect(vm_candidates.count).to eq 1
    expect(vm_candidates.first.tenants.first).to eq t
  end

  context 'appliance optimization policy params is nil' do
    it 'does not fail' do
      appl = build(:appliance, optimization_policy_params: nil)
      manual_strategy = Atmosphere::OptimizationStrategy::Manual.new(appl)
      manual_strategy.new_vms_tmpls_and_flavors_and_tenants
    end

    it 'returns empty array' do
      appl = build(:appliance, optimization_policy_params: nil)
      manual_strategy = Atmosphere::OptimizationStrategy::Manual.new(appl)
      expect(manual_strategy.new_vms_tmpls_and_flavors_and_tenants).to be_empty
    end
  end
  context 'vms parameter is nil' do
    it 'does not fail' do
      appl = build(:appliance, optimization_policy_params: { vms: nil })
      manual_strategy = Atmosphere::OptimizationStrategy::Manual.new(appl)
      manual_strategy.new_vms_tmpls_and_flavors_and_tenants
    end

    it 'returns empty array' do
      appl = build(:appliance, optimization_policy_params: { vms: nil })
      manual_strategy = Atmosphere::OptimizationStrategy::Manual.new(appl)
      expect(manual_strategy.new_vms_tmpls_and_flavors_and_tenants).to be_empty
    end
  end

  it 'does not support dev mode appliance set' do
    as = build(:dev_appliance_set)
    expect(Atmosphere::OptimizationStrategy::Manual.supports?(as)).to be_falsy
  end

  it 'supports portal appliance set' do
    as = build(:portal_appliance_set)
    expect(Atmosphere::OptimizationStrategy::Manual.supports?(as)).to be_truthy
  end

  it 'supports workflow appliance set' do
    as = build(:workflow_appliance_set)
    expect(Atmosphere::OptimizationStrategy::Manual.supports?(as)).to be_truthy
  end
end
