require 'rails_helper'

describe AppliancesAffectedByPmt do
  before do
    allow(Optimizer).to receive(:instance).and_return(double(run: true))
  end

  let!(:at) { create(:appliance_type) }
  let!(:pmt) { create(:port_mapping_template, appliance_type: at) }
  let!(:pmp) { create(:pmt_property, port_mapping_template: pmt) }

  context 'in production mode' do
    let!(:appl1) { create(:appliance, appliance_type: at) }

    it 'finds affected appliances using appliance_type relation' do
      create(:appliance)

      affected_appl = AppliancesAffectedByPmp.new(pmp).find

      expect(affected_appl.size).to eq 1
      expect(affected_appl.first).to eq appl1
    end

    it 'returns appliance which can be updated' do
      affected_appl = AppliancesAffectedByPmp.new(pmp).find.first

      expect(affected_appl.readonly?).to be_falsy
    end
  end

  context 'in development mode' do
    it 'finds affected appliances using dev_mode_property_set relation' do
      dev_as = create(:dev_appliance_set)
      appl1 = create(:appliance, appliance_type: at, appliance_set: dev_as)
      create(:appliance, appliance_type: at)
      dev_pmp = appl1.dev_mode_property_set.port_mapping_templates.first.port_mapping_properties.first

      affected_appl = AppliancesAffectedByPmp.new(dev_pmp).find

      expect(affected_appl.size).to eq 1
      expect(affected_appl.first).to eq appl1
    end
  end
end