require 'rails_helper'

describe Atmosphere::ApplianceTypeSerializer do
  include VmtOnTHelpers

  it 'is inactive when all VMT started on turned off tenant' do
    _, inactive_vmt = vmt_on_tenant(t_active: false)
    at = create(:appliance_type, virtual_machine_templates: [inactive_vmt])
    serializer = Atmosphere::ApplianceTypeSerializer.new(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['active']).to be_falsy
  end

  it 'returns information about only active tenants' do
    _, inactive_vmt = vmt_on_tenant(t_active: false)
    active_t, active_vmt = vmt_on_tenant(t_active: true)
    at = create(:appliance_type,
      virtual_machine_templates: [inactive_vmt, active_vmt])
    serializer = Atmosphere::ApplianceTypeSerializer.new(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['tenant_ids']).to eq [active_t.id]
  end
end
