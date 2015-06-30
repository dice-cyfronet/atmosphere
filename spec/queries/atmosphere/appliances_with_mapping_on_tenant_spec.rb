require 'rails_helper'

describe Atmosphere::AppliancesWithMappingOnTenant do
  let(:t) { create(:tenant) }
  let(:t_appl1) { create(:appliance) }
  let(:t_appl2) { create(:appliance) }
  let(:other_appl) { create(:appliance) }

  let(:pmt) { create(:port_mapping_template) }

  let!(:t_mapping1) { create(:http_mapping, tenant: t, appliance: t_appl1) }
  let!(:t_mapping2) { create(:http_mapping, tenant: t, appliance: t_appl2) }
  let!(:t_mapping3) { create(:http_mapping, appliance: other_appl) }

  subject { Atmosphere::AppliancesWithMappingOnTenant.new(t) }

  it 'returns appliances with http mapping deployed on tenant' do
    appliances = subject.find

    expect(appliances.size).to eq 2
    expect(appliances).to include t_appl1
    expect(appliances).to include t_appl2
  end
end