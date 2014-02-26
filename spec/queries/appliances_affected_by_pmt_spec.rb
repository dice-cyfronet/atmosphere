require 'spec_helper'

describe AppliancesAffectedByPmt do
  before do
    Optimizer.stub(:instance).and_return(double(run: true))
  end

  let!(:at) { create(:appliance_type) }
  let!(:pmt) { create(:port_mapping_template, appliance_type: at) }

  context 'in production mode' do
    it 'finds affected appliances using appliance_type relation' do
      appl1 = create(:appliance, appliance_type: at)
      create(:appliance)

      affected_appl = AppliancesAffectedByPmt.new(pmt).find

      expect(affected_appl.size).to eq 1
      expect(affected_appl.first).to eq appl1
    end
  end

  context 'in development mode' do
    it 'finds affected appliances using dev_mode_property_set relation' do
      dev_as = create(:dev_appliance_set)
      appl1 = create(:appliance, appliance_type: at, appliance_set: dev_as)
      create(:appliance, appliance_type: at)
      dev_pmt = appl1.dev_mode_property_set.port_mapping_templates.first

      affected_appl = AppliancesAffectedByPmt.new(dev_pmt).find

      expect(affected_appl.size).to eq 1
      expect(affected_appl.first).to eq appl1
    end
  end
end