require 'spec_helper'

describe ApplianceTypeSerializer do
  it 'is inactive when all VMT started on turned off compute site' do
    inactive_cs = create(:compute_site, active: false)
    vmt = create(:virtual_machine_template, compute_site: inactive_cs)
    at = create(:appliance_type, virtual_machine_templates: [vmt])
    serializer = ApplianceTypeSerializer.new(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['active']).to be_false
  end
end