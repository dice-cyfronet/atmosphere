require 'rails_helper'

describe Atmosphere::ApplianceCreator do

  let(:user) { create(:user) }
  let(:at) { create(:filled_appliance_type, visible_to: 'all') }
  let(:cfg_tmpl) { create(:appliance_configuration_template, appliance_type: at)}
  let(:as) { create(:appliance_set, user: user)}
  let!(:active_t) { create(:tenant, active: true) }
  let!(:inactive_t) { create(:tenant, active: false) }

  context 'tenant ids not provided' do

    it 'creates appliance with allowed active tenant only' do
      created_appl_params = ActionController::Parameters.
                              new(appliance_set_id: as.id,
                                  configuration_template_id: cfg_tmpl.id)
      creator = Atmosphere::ApplianceCreator.
                  new(created_appl_params, 'dummy-token')

      appl = creator.build

      expect(appl.tenants).to eq [active_t]
      expect(appl.tenants.first.active).to be true
    end

  end

  context 'tenant ids provided' do

    it 'creates appliance with allowed active tenants only' do
      created_appl_params = ActionController::Parameters.
                              new(appliance_set_id: as.id,
                                  configuration_template_id: cfg_tmpl.id,
                                  tenant_ids: [active_t, inactive_t])
      creator = Atmosphere::ApplianceCreator.
                  new(created_appl_params, 'dummy-token')

      appl = creator.build

      expect(appl.tenants).to eq [active_t]
      expect(appl.tenants.first.active).to be true
    end
  end

  it 'creates appliance with optimization policy params' do
    vms = [
      { 'cpu' => 1, 'mem' => 512, 'tenant_ids' => [1] },
      { 'cpu' => 2, 'mem' => 1024, 'tenant_ids' => [1] }
    ]
    created_appl_params = ActionController::Parameters.
                          new(appliance_set_id: as.id,
                              configuration_template_id: cfg_tmpl.id,
                              vms: vms)
    creator = Atmosphere::ApplianceCreator.
              new(created_appl_params, 'dummy-token')

    appl = creator.build

    expect(appl.optimization_policy_params[:vms]).to eq vms
  end

end