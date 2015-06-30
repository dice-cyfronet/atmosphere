require 'rails_helper'

describe Atmosphere::ApplianceSerializer do
  it 'returns information about connected VMs' do
    t = create(:tenant)
    vm1 = create(:virtual_machine, tenant: t)
    vm2 = create(:virtual_machine, tenant: t)
    appliance = build(:appliance, virtual_machines: [vm1, vm2])
    serializer = Atmosphere::ApplianceSerializer.new(appliance)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance']['virtual_machine_ids']).to include(vm1.id, vm2.id)
  end
end