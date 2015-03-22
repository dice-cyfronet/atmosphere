require 'rails_helper'

describe Atmosphere::OptimizationStrategy::Manual do

  before do
    Fog.mock!
    allow(Atmosphere::Optimizer.instance).to receive(:run)
  end

  let!(:fund) { create(:fund) }
  let(:cs) { create(:compute_site, active: true, funds: [fund]) }
  let(:at) { create(:filled_appliance_type, visible_to: 'all', preference_disk: 0) }
  let!(:tmpl) { create(:virtual_machine_template, appliance_type: at, compute_site: cs) }
  let!(:fl1) { create(:virtual_machine_flavor, cpu: 1, memory: 512, compute_site: cs, active: true) }
  let!(:fl2) { create(:virtual_machine_flavor, cpu: 2, memory: 1024, compute_site: cs, active: true) }
  let(:cfg_tmpl) { create(:appliance_configuration_template, appliance_type: at)}
  let(:user) { create(:user) }
  let(:as) { create(:appliance_set, user: user)}

  it 'return templates and flavors for each defined vm in opt policy params' do

    fl1.set_hourly_cost_for(at.os_family, 5)
    fl2.set_hourly_cost_for(at.os_family, 10)

    fl1.reload
    fl2.reload

    vms = [
           { 'cpu' => 1, 'mem' => 512, 'compute_site_ids' => [cs.id] },
           { 'cpu' => 2, 'mem' => 1024, 'compute_site_ids' => [cs.id] }
          ]
    created_appl_params = ActionController::Parameters.new(
        {
          appliance_set_id: as.id,
          configuration_template_id: cfg_tmpl.id,
          vms: vms
        }
      )
    creator = Atmosphere::ApplianceCreator.new(created_appl_params, 'dummy-token')
    appl = creator.build
    appl.save!

    manual_policy = Atmosphere::OptimizationStrategy::Manual.new(appl)

    tmpls_and_flavors = manual_policy.new_vms_tmpls_and_flavors

    expect(tmpls_and_flavors.size).to eq 2
    expect(tmpls_and_flavors[0][:template]).to eq tmpl
    expect(tmpls_and_flavors[0][:flavor]).to eq fl1
    expect(tmpls_and_flavors[1][:template]).to eq tmpl
    expect(tmpls_and_flavors[1][:flavor]).to eq fl2
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
end