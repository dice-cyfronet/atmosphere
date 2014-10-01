#require 'spec_helper'
require 'rails_helper'

describe Atmosphere::Cloud::VmTagsManager do

  it 'tags worker is invoked' do

    server_name = 'SERVER NAME'
    server_id = 'SERVER_ID'
    u1 = create(:user, login: 'user1')
    u2 = create(:user,login: 'user2')
    at = create(:appliance_type)
    a_set_1 = create(:appliance_set, user: u1)
    a_set_2 = create(:appliance_set, user: u2)
    appl1 = create(:appliance, appliance_type: at, appliance_set: a_set_1)
    appl2 = create(:appliance, appliance_type: at, appliance_set: a_set_2)
    cs = create(:compute_site)
    vm = create(:virtual_machine, appliances: [appl1, appl2], compute_site: cs, id_at_site: server_id)

    expect(Atmosphere::VmTagsCreatorWorker).to receive(:perform_async)
      .with(vm.id, {'Name' => vm.name, 'Appliance type name' => appl1.appliance_type.name,
        'Users' => 'user1, user2'})
    subject.create_tags_for_vm(vm)
  end
end