require 'rails_helper'

describe Atmosphere::Cloud::VmTagsManager do
  it 'tags worker is invoked' do
    u1 = create(:user, login: 'user1')
    u2 = create(:user, login: 'user2')
    at = create(:appliance_type)
    a_set_1 = create(:appliance_set, user: u1)
    a_set_2 = create(:appliance_set, user: u2)
    appl1 = create(:appliance, appliance_type: at, appliance_set: a_set_1)
    appl2 = create(:appliance, appliance_type: at, appliance_set: a_set_2)
    t = create(:tenant)
    vm = create(:virtual_machine,
                appliances: [appl1, appl2],
                tenant: t, id_at_site: 'SERVER_ID')

    expect(Atmosphere::VmTagsCreatorWorker).
      to receive(:perform_async) do |vm_id, hsh|
        expect(vm_id).to eq vm.id
        expect(hsh['Appliance type name']).to eq at.name
        expect(hsh['Users'].split(', ')).to include 'user1', 'user2'
      end

    described_class.new(vm).execute
  end
end
