require 'rails_helper'

describe Atmosphere::AppliancesAffectedByPmt do
  before do
    allow(Atmosphere::Optimizer)
      .to receive(:instance).and_return(double(run: true))
  end

  let!(:at) { create(:appliance_type) }
  let!(:pmt) { create(:port_mapping_template, appliance_type: at) }

  context 'in production mode' do
    let!(:appl1) { create(:appliance, appliance_type: at) }

    it 'finds affected appliances using appliance_type relation' do
      # other appliances which should not be taken into account
      create(:appliance)
      dev_appliance

      affected_appl = Atmosphere::AppliancesAffectedByPmt.new(pmt).find

      expect(affected_appl.size).to eq 1
      expect(affected_appl.first).to eq appl1
    end

    it 'returns appliance which can be updated' do
      affected_appl = Atmosphere::AppliancesAffectedByPmt.new(pmt).find.first

      expect(affected_appl.readonly?).to be_falsy
    end
  end

  context 'in development mode' do
    it 'finds affected appliances using dev_mode_property_set relation' do
      appl1 = dev_appliance
      dev_pmt = appl1.dev_mode_property_set.port_mapping_templates.first
      # other appliances which should not be taken into account
      create(:appliance, appliance_type: at)

      affected_appl = Atmosphere::AppliancesAffectedByPmt.new(dev_pmt).find

      expect(affected_appl.size).to eq 1
      expect(affected_appl.first).to eq appl1
    end
  end

  def dev_appliance
    dev_as = create(:dev_appliance_set)
    create(:appliance, appliance_type: at, appliance_set: dev_as)
  end
end