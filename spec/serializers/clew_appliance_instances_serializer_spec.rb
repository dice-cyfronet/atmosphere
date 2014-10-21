require 'rails_helper'

describe ClewApplianceInstancesSerializer do
  it 'returns only owned http_mappings' do
    at = create(:appliance_type)
    pmt = create(:port_mapping_template, appliance_type: at)
    as, http_m = appliance_with_http_mapping_for(as, at, pmt)
    appliance_with_http_mapping_for(at, pmt)
    serializer = ClewApplianceInstancesSerializer.new(appliance_sets: [as])

    result = JSON.parse(serializer.to_json)
    appl = result['clew_appliance_instances']['appliances'].first
    port_mappings = appl['port_mapping_templates'].first['http_mappings']

    expect(port_mappings.size).to eq 1
    expect(port_mappings.first['id']).to eq http_m.id
  end

  def appliance_with_http_mapping_for(as = create(:appliance_set), at, pmt)
    as = create(:appliance_set, appliance_set_type: :portal)
    appl = create(:appliance, appliance_type: at, appliance_set: as)
    http_m = create(:http_mapping, appliance: appl, port_mapping_template: pmt)

    return as, http_m
  end
end
