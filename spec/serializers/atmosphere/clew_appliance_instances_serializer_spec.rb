require 'rails_helper'

describe Atmosphere::ClewApplianceInstancesSerializer do
  it 'returns only owned http_mappings' do
    at = create(:appliance_type)
    pmt = create(:port_mapping_template, appliance_type: at)
    as, http_m = appliance_with_http_mapping_for(as, at, pmt)
    appliance_with_http_mapping_for(at, pmt)
    serializer = Atmosphere::ClewApplianceInstancesSerializer.new(appliance_sets: [as])

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

  it 'returns information about all port mapping templates' do
    at = create(:appliance_type)
    pmt = create(:port_mapping_template, appliance_type: at)
    as = create(:appliance_set, appliance_set_type: :portal)
    appl = create(:appliance, appliance_type: at, appliance_set: as)
    serializer = Atmosphere::ClewApplianceInstancesSerializer.new(appliance_sets: [as])
    result = JSON.parse(serializer.to_json)
    appl = result['clew_appliance_instances']['appliances'].first
    port_mapping_templates = appl['port_mapping_templates']

    expect(port_mapping_templates.size).to eq 1
    expect(port_mapping_templates.first['id']).to eq pmt.id
  end

  it 'returns information about appliance source appliance type' do
    at = create(:appliance_type)
    as = create(:appliance_set, appliance_set_type: :portal)
    create(:appliance, appliance_type: at, appliance_set: as)

    serializer = Atmosphere::ClewApplianceInstancesSerializer.
                 new(appliance_sets: [as])

    result = JSON.parse(serializer.to_json)
    appl = result['clew_appliance_instances']['appliances'].first

    expect(appl['appliance_type_id']).to eq at.id
  end
end
