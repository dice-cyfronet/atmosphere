require 'rails_helper'

describe ApplianceSerializer do
  it 'returns information about connected VMs' do
    cs = create(:compute_site)
    vm1 = create(:virtual_machine, compute_site: cs)
    vm2 = create(:virtual_machine, compute_site: cs)
    appliance = build(:appliance, virtual_machines: [vm1, vm2])
    serializer = ApplianceSerializer.new(appliance)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance']['virtual_machine_ids']).to include(vm1.id, vm2.id)
  end
end