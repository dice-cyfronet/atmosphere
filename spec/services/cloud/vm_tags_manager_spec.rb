require 'spec_helper'

describe Cloud::VmTagsManager do

  it 'tags are created for reused vm' do
    vm = double('virtual machine')
    server_name = 'SERVER NAME'
    server_id = 'SERVER_ID'
    cs_id = 1
    u1 = double('user1')
    expect(u1).to receive(:login).and_return 'user1'
    u2 = double('user2')
    expect(u2).to receive(:login).and_return 'user2'
    at = double('appliance type')
    allow(at).to receive(:name).and_return('Ubuntu')
    appl1 = double('first appliance')
    appl2 = double('second appliance')
    allow(appl1).to receive(:appliance_type).and_return(at)
    allow(appl2).to receive(:appliance_type).and_return(at)
    a_set_1 = double('appliance set 1')
    a_set_2 = double('appliance set 2')
    expect(a_set_1).to receive(:user).and_return u1
    expect(a_set_2).to receive(:user).and_return u2
    expect(appl1).to receive(:appliance_set).and_return a_set_1
    expect(appl2).to receive(:appliance_set).and_return a_set_2
    expect(vm).to receive(:appliances).and_return [appl1, appl2]
    cs = double('compute site')
    allow(vm).to receive(:compute_site).and_return cs
    allow(vm).to receive(:id_at_site).and_return server_id
    allow(vm).to receive(:name).and_return server_name
    allow(vm).to receive(:appliance_type).and_return at
    allow(cs).to receive(:id).and_return cs_id
    expect(VmTagsCreatorWorker).to receive(:perform_async)
      .with(server_id, cs_id, {'Name' => vm.name, 'Appliance type name' => appl1.appliance_type.name, 'Users' => 'user1, user2'})
    subject.create_tags_for_vm(vm)
  end
end