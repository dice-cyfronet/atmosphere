require 'spec_helper'

describe VmMonitoringWorker do

  before { Fog.mock! }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end
  end

  context 'updating cloud site virtual machines' do
    let(:cyfronet_folsom) { create(:compute_site, site_id: 'cyfronet-folsom', config: '{"provider": "openstack", "openstack_auth_url": "http://10.10.0.2:5000/v2.0/tokens", "openstack_api_key": "key", "openstack_username": "vphadmin"}') }

    let!(:ubuntu) { create(:virtual_machine_template, id_at_site: 'ubuntu', compute_site: cyfronet_folsom, state: :active) }

    let(:vm1_data) { vm '1', 'vm1', :active }
    let(:vm2_data) { vm '2', 'vm2', :booting }
    let(:vm3_data) { vm '3', 'vm3', :error }

    before do
      # Fog::Compute[:openstack].reset
      data = Fog::Compute[:openstack].data
      # Fog::Compute::OpenStack::Mock.reset
      # data = Fog::Compute::OpenStack::Mock.data
      servers = data[:servers]

      servers['1'] = vm1_data
      servers['2'] = vm2_data
      servers['3'] = vm3_data
    end

    context 'when no VMs registered' do
      it 'creates 3 new VMs' do
        expect {
          subject.perform(cyfronet_folsom.id)
        }.to change{ VirtualMachine.count }.by(3)
      end

      it 'creates new VMs and set details' do
        subject.perform(cyfronet_folsom.id)

        vm1 = VirtualMachine.find_by(id_at_site: '1')
        vm2 = VirtualMachine.find_by(id_at_site: '2')
        vm3 = VirtualMachine.find_by(id_at_site: '3')

        expect(vm1).to vm_fog_data_equals vm1_data, ubuntu
        expect(vm2).to vm_fog_data_equals vm2_data, ubuntu
        expect(vm3).to vm_fog_data_equals vm3_data, ubuntu
      end
    end

    context 'when some VMs exist' do
      let!(:vm2) { create(:virtual_machine, id_at_site: '2', state: :booting, name: 'old_name', source_template: ubuntu, compute_site: cyfronet_folsom)}

      it 'does not create duplicated VMs' do
        expect {
          subject.perform(cyfronet_folsom.id)
        }.to change{ VirtualMachine.count }.by(2)
      end

      it 'updates existing VM details' do
        subject.perform(cyfronet_folsom.id)
        vm2 = VirtualMachine.find_by(id_at_site: '2')

        expect(vm2).to vm_fog_data_equals vm2_data, ubuntu
      end
    end

    context 'when VM removed on cloud site' do
      before do
        create(:virtual_machine, id_at_site: '1', state: :booting, name: 'vm1', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '2', state: :booting, name: 'vm2', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '3', state: :booting, name: 'vm3', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '4', state: :booting, name: 'vm4', source_template: ubuntu, compute_site: cyfronet_folsom)
      end

      it 'removes deleted VM' do
        expect {
          subject.perform(cyfronet_folsom.id)
        }.to change{ VirtualMachine.count }.by(-1)
      end
    end
  end

  def vm(id, name, status)
    {
      "id" => id,
      "addresses" => {"private"=>[{"version"=>4, "addr"=>"10.100.8.18"}]},
      "image" => {
        "id" => "ubuntu",
        "links" => [
            {"href" => "http://10.100.0.24:8774/a0297dad2a9f40dc9bda6eacd43d488a/images/addc2222-9632-468e-8b78-18c74d9df6ef", "rel" => "bookmark"}
        ]
      },
      "name" => name,
      "state" => status.to_s.upcase,
      "key_name" => "jm",
      "fault" => nil
    }
  end
end