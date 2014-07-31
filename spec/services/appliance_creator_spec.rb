require 'rails_helper'

describe ApplianceCreator do

  let(:user) { create(:user) }
  let(:at) { create(:filled_appliance_type, visible_to: 'all') }
  let(:cfg_tmpl) { create(:appliance_configuration_template, appliance_type: at)}
  let(:as) { create(:appliance_set, user: user)}
  let!(:active_cs) { create(:compute_site, active: true) }
  let!(:inactive_cs) { create(:compute_site, active: false) }

  context 'compute site ids not provided' do

    it 'creates appliance with allowed active compute site only' do
      created_appl_params = ActionController::Parameters.new(
        {       
          appliance_set_id: as.id,
          configuration_template_id: cfg_tmpl.id
        }
      )
      creator = ApplianceCreator.new(created_appl_params, 'dummy-token')
      appl = creator.create!
      expect(appl.compute_sites.count).to eq 1
      expect(appl.compute_sites.first.active).to be true
    end

  end

  context 'compute site ids provided' do

    it 'creates appliance with allowed active compute site only' do
      created_appl_params = ActionController::Parameters.new(
        {       
          appliance_set_id: as.id,
          configuration_template_id: cfg_tmpl.id,
          compute_site_ids: [active_cs.id, inactive_cs.id]
        }
      )
      creator = ApplianceCreator.new(created_appl_params, 'dummy-token')
      appl = creator.create!
      expect(appl.compute_sites.count).to eq 1
      expect(appl.compute_sites.first.active).to be true
    end

  end

end