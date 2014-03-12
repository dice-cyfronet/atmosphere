require 'spec_helper'

describe ComputeSiteHttpMappings do

  let(:cs)   { create(:compute_site) }
  let(:vm)   { create(:virtual_machine, compute_site: cs) }
  let(:appl) { create(:appliance, virtual_machines: [vm]) }
  let(:pmt)  { create(:port_mapping_template) }

  let!(:appl_mapping1) do
    create(:http_mapping,
      appliance: appl,
      application_protocol: :http,
      compute_site: cs,
      port_mapping_template: pmt)
  end

  let!(:appl_mapping2) do
    create(:http_mapping,
      appliance: appl,
      application_protocol: :https,
      compute_site: cs,
      port_mapping_template: pmt)
  end

  let!(:other_mapping) do
    create(:http_mapping,
      application_protocol: :http,
      port_mapping_template: pmt)
  end

  subject { ComputeSiteHttpMappings.new(cs) }

  it 'returns comptue site mappings' do
    mappings = subject.find

    expect(mappings.size).to eq 2
    expect(mappings).to include appl_mapping1
    expect(mappings).to include appl_mapping2
  end

  it 'returns only http mapping when type option is set' do
    mappings = subject.find(protocol: :http)

    expect(mappings.size).to eq 1
    expect(mappings).to include appl_mapping1
  end
end