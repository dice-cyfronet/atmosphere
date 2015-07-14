require 'rails_helper'

describe Atmosphere::ApplianceTypeSerializer do
  include VmtOnTHelpers

  it 'is inactive when all VMT started on turned off compute site' do
    _, inactive_vmt = vmt_on_tenant(t_active: false)
    at = create(:appliance_type, virtual_machine_templates: [inactive_vmt])
    #serializer = Atmosphere::ApplianceTypeSerializer.new(at)
    @current_user = create(:user)

    serializer = slizer(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['active']).to be_falsy
  end

  it 'returns information about only active compute site' do
    f = create(:fund)
    @current_user = create(:user, funds: [f])
    inactive_t, inactive_vmt = vmt_on_tenant(t_active: false)
    active_t, active_vmt = vmt_on_tenant(t_active: true)
    inactive_t.funds = [f]
    active_t.funds = [f]
    inactive_t.save
    active_t.save
    at = create(:appliance_type,
      virtual_machine_templates: [inactive_vmt, active_vmt])

    serializer = slizer(at)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_type']['compute_site_ids']).to eq [active_t.id]
  end

  private

  def slizer(at)
    serializer = Atmosphere::ApplianceTypeSerializer.new(at, { scope: @current_user })
    def serializer.current_user() scope end
    serializer
  end

end
