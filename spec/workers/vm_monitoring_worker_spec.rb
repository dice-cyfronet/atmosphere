require 'spec_helper'

describe VmMonitoringWorker do
  include FogHelpers

  before { Fog.mock! }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end

    it { should be_retryable false }
    it { should be_processed_in :monitoring }
  end

  context 'updating cloud site virtual machines' do
    let(:cyfronet_folsom) { create(:compute_site, site_id: 'cyfronet-folsom', config: '{"provider": "openstack", "openstack_auth_url": "http://10.10.0.2:5000/v2.0/tokens", "openstack_api_key": "key", "openstack_username": "user"}') }

    let!(:ubuntu) { create(:virtual_machine_template, id_at_site: 'ubuntu', compute_site: cyfronet_folsom, state: :active) }

    let(:vm1_data) { vm('1', 'vm1', :active, '10.100.1.1') }
    let(:vm2_data) { vm('2', 'vm2', :build, '10.100.1.2') }
    let(:vm3_data) { vm('3', 'vm3', :error, '10.100.1.3') }
    let(:vm4_data) { vm_with_address_hash('4', 'vm4', :error, {}) }

    before do
      data = cyfronet_folsom.cloud_client.data
      servers = data[:servers]

      servers['1'] = vm1_data
      servers['2'] = vm2_data
      servers['3'] = vm3_data
      servers['4'] = vm4_data
    end

    context 'when no VMs registered' do
      it 'creates 4 new VMs' do
        expect {
          subject.perform(cyfronet_folsom.id)
        }.to change{ VirtualMachine.count }.by(4)
      end

      context 'with vms details' do
        before do
          subject.perform(cyfronet_folsom.id)
        end

        let(:vm1) { VirtualMachine.find_by(id_at_site: '1') }
        let(:vm2) { VirtualMachine.find_by(id_at_site: '2') }
        let(:vm3) { VirtualMachine.find_by(id_at_site: '3') }
        let(:vm4) { VirtualMachine.find_by(id_at_site: '4') }

        it 'creates new VMs and set details' do
          expect(vm1).to vm_fog_data_equals vm1_data, ubuntu
          expect(vm2).to vm_fog_data_equals vm2_data, ubuntu
          expect(vm3).to vm_fog_data_equals vm3_data, ubuntu
          expect(vm4).to vm_fog_data_equals vm4_data, ubuntu
        end

        it 'sets IP only when active or error VM state (only when id is available)' do
          expect(vm1.ip).to eq '10.100.1.1'
          expect(vm2.ip).to be_nil
          expect(vm3.ip).to eq '10.100.1.3'
          expect(vm4.ip).to be_nil
        end
      end
    end

    context 'when some VMs exist' do
      let!(:vm2) { create(:virtual_machine, id_at_site: '2', state: :build,name: 'old_name', source_template: ubuntu, compute_site: cyfronet_folsom)}

      it 'does not create duplicated VMs' do
        expect {
          subject.perform(cyfronet_folsom.id)
        }.to change{ VirtualMachine.count }.by(3)
      end

      it 'updates existing VM details' do
        subject.perform(cyfronet_folsom.id)
        vm2 = VirtualMachine.find_by(id_at_site: '2')

        expect(vm2).to vm_fog_data_equals vm2_data, ubuntu
      end
    end

    context 'when VM removed on cloud site' do
      before do
        create(:virtual_machine, id_at_site: '1', state: :build, name: 'vm1', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '2', state: :build, name: 'vm2', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '3', state: :build, name: 'vm3', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '4', state: :build, name: 'vm4', source_template: ubuntu, compute_site: cyfronet_folsom)
        create(:virtual_machine, id_at_site: '5', state: :build, name: 'vm5', source_template: ubuntu, compute_site: cyfronet_folsom)
      end

      it 'removes deleted VM' do
        expect {
          subject.perform(cyfronet_folsom.id)
        }.to change{ VirtualMachine.count }.by(-1)
      end
    end

    context 'when fog error occurs' do
      let(:cloud_client) { double }
      let(:logger) { double }

      before do
        Rails.stub(:logger).and_return(logger)
        expect(logger).to receive(:error)

        ComputeSite.any_instance.stub(:cloud_client).and_return(cloud_client)
        allow(cloud_client).to receive(:servers).and_raise(Excon::Errors::Unauthorized.new 'error')
      end

      it 'logs error into rails logs' do
        subject.perform(cyfronet_folsom.id)
      end
    end
  end
end