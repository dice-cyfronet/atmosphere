require 'spec_helper'

describe AppliancesWithMappingOnComputeSite do
  let(:cs) { create(:compute_site) }
  let(:cs_appl1) { create(:appliance) }
  let(:cs_appl2) { create(:appliance) }
  let(:other_appl) { create(:appliance) }

  let(:pmt) { create(:port_mapping_template) }

  let!(:cs_mapping1) { create(:http_mapping, compute_site: cs, appliance: cs_appl1) }
  let!(:cs_mapping2) { create(:http_mapping, compute_site: cs, appliance: cs_appl2) }
  let!(:cs_mapping3) { create(:http_mapping, appliance: other_appl) }

  subject { AppliancesWithMappingOnComputeSite.new(cs) }

  it 'returns appliances with http mapping deployed on compute site' do
    appliances = subject.find

    expect(appliances.size).to eq 2
    expect(appliances).to include cs_appl1
    expect(appliances).to include cs_appl2
  end
end