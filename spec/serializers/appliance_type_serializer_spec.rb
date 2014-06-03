require 'spec_helper'

describe ApplianceTypeSerializer do
  include VmtOnCsHelpers

  it 'is inactive when all VMT started on turned off compute site' do
    _, inactive_vmt = vmt_on_site(cs_active: false)
    at = create(:appliance_type, virtual_machine_templates: [inactive_vmt])
    serializer = ApplianceTypeSerializer.new(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['active']).to be_false
  end

  it 'returns information about only active comptue sites' do
    _, inactive_vmt = vmt_on_site(cs_active: false)
    active_cs, active_vmt = vmt_on_site(cs_active: true)
    at = create(:appliance_type,
      virtual_machine_templates: [inactive_vmt, active_vmt])
    serializer = ApplianceTypeSerializer.new(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['compute_site_ids']).to eq [active_cs.id]
  end
end
