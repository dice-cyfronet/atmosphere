require 'spec_helper'

describe Cloud::VmTagsManager do

  it 'tags worker is invoked' do
    
    server_name = 'SERVER NAME'
    server_id = 'SERVER_ID'
    cs_id = 1
    u1 = double('user1', login: 'user1')
    u2 = double('user2',login: 'user2')
    at = double('appliance type',name: 'Ubuntu')
    a_set_1 = double('appliance set 1', user: u1)
    a_set_2 = double('appliance set 2', user: u2)
    appl1 = double('first appliance', appliance_type: at, appliance_set: a_set_1)
    appl2 = double('second appliance', appliance_type: at, appliance_set: a_set_2)
    cs = double('compute site', id: cs_id)
    vm = double('virtual machine', appliances: [appl1, appl2], compute_site: cs, id_at_site: server_id,
        name: server_name, appliance_type: at)
    
    expect(VmTagsCreatorWorker).to receive(:perform_async)
      .with(server_id, cs_id, {'Name' => vm.name, 'Appliance type name' => appl1.appliance_type.name,
        'Users' => 'user1, user2'})
    subject.create_tags_for_vm(vm)
  end
end