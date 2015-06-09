require 'rails_helper'

describe Atmosphere::VmUpdater do
  let(:cs)  { create(:compute_site) }
  let!(:flavor) { create(:virtual_machine_flavor, compute_site: cs) }
  let(:vmt) { create(:virtual_machine_template, compute_site: cs) }

  let(:updater) { double('updater', update: true) }
  let(:updater_class) { double('updater_class', new: updater) }

  let(:updated_vm) { Atmosphere::VirtualMachine.find_by(id_at_site: 'id_at_site') }

  before do
    allow(Atmosphere::VirtualMachineTemplate).
      to receive(:find_by).
      with(compute_site: cs, id_at_site: 'vmt_id_at_site').
      and_return(vmt)
    #Zabbix.stub(:register_host).and_return 1
    #Zabbix.stub(:unregister_host)
    #Zabbix.stub(:host_metrics)
  end

  subject { Atmosphere::VmUpdater.new(cs, server, updater_class) }

  describe 'VM states' do
    it 'is saving when task state equals to image_snapshot' do
      saving_when_task_state('image_snapshot')
    end

    it 'is saving when task state equals to image_pending_upload' do
      saving_when_task_state('image_pending_upload')
    end

    def saving_when_task_state(state)
      server = server_double(state: 'active',
                             task_state: state,
                             flavor: { 'id' => '1' })
      updater = Atmosphere::VmUpdater.new(cs, server, updater_class)

      vm = updater.execute

      expect(vm.state).to eq 'saving'
    end

    context 'when relation to saved_templates is not empty' do
      let(:server) do
        server_double(state: 'active',
                      flavor: {'id' => "1"})
      end

      before do
        vm = create(:virtual_machine,
                    id_at_site: 'id_at_site',
                    saved_templates: [vmt],
                    compute_site: cs,
                    created_at: old_vm_creation_time)

        vm.saved_templates << vmt
      end

      subject { Atmosphere::VmUpdater.new(cs, server, updater_class) }

      it 'sets "saving" state' do
        vm = subject.execute
        expect(vm.state).to eq 'saving'
      end
    end
  end

  describe 'status/ip updater' do
    context 'when active state' do
      let(:server) do
        server_double(state: 'active',
          public_ip_address: '10.100.1.2')
      end

      it 'invokes updater when ip changed' do
        vm = create(:virtual_machine,
                    id_at_site: 'id_at_site',
                    compute_site: cs,
                    created_at: old_vm_creation_time)
        appl1 = create(:appliance, virtual_machines: [vm])
        appl2 = create(:appliance, virtual_machines: [vm])
        appl_updater = double

        expect(updater_class).to receive(:new).with(appl1).and_return(appl_updater)
        expect(updater_class).to receive(:new).with(appl2).and_return(appl_updater)
        expect(appl_updater).to receive(:update).twice

        subject.execute
      end

      it 'does not invoke updater when ip not changed' do
        vm = create(:virtual_machine,
          id_at_site: 'id_at_site',
          compute_site: cs, ip: '10.100.1.2')
        create(:appliance, virtual_machines: [vm])

        expect(updater).to_not receive(:update)

        subject.execute
      end

      it 'does not invoke updater when no vm appliances' do
        create(:virtual_machine, id_at_site: 'id_at_site', compute_site: cs)

        expect(updater).to_not receive(:update)

        subject.execute
      end

      it 'invokes updater when VM with IP changed state to active' do
        vm = create(:virtual_machine,
                    id_at_site: 'id_at_site',
                    ip: '10.100.1.2',
                    compute_site: cs,
                    state: :shutoff,
                    created_at: old_vm_creation_time)
        appl1 = create(:appliance, virtual_machines: [vm])

        expect(updater).to receive(:update)

        subject.execute
      end

      it 'does not invoke updter when VM without IP state changed to active' do
        vm = create(:virtual_machine,
                id_at_site: 'id_at_site',
                ip: nil,
                compute_site: cs,
                state: :shutoff)
        appl1 = create(:appliance, virtual_machines: [vm])
        server = server_double(state: 'active', public_ip_address: nil)

        expect(updater).not_to receive(:update)

        Atmosphere::VmUpdater.new(cs, server, updater_class).execute
      end
    end

    context 'when other than active state' do

      let(:server) do
        server_double(state: 'error',
          public_ip_address: '10.100.1.2')
      end

      it 'invokes updater when state changed to other' do
        vm = create(:virtual_machine,
                    id_at_site: 'id_at_site',
                    state: :active,
                    compute_site: cs,
                    ip: '10.100.1.2',
                    created_at: old_vm_creation_time)
        appl = create(:appliance, virtual_machines: [vm])
        appl_updater = double

        expect(updater_class).
          to receive(:new).
          with(appl).
          and_return(appl_updater)
        expect(appl_updater).
          to receive(:update).
          once

        subject.execute
      end

      it 'does not invoke update when state changed to !active' do
        create(:virtual_machine,
          id_at_site: 'id_at_site',
          state: :build, compute_site: cs)

        expect(updater).to_not receive(:update)

        subject.execute
      end

      it 'does not invoke updater even when ip changed' do
        create(:virtual_machine,
          id_at_site: 'id_at_site',
          ip: '10.100.1.3',
          state: :build, compute_site: cs)

        expect(updater).to_not receive(:update)

        subject.execute
      end
    end
  end

  context 'when active VM on cloud' do
    let(:server) do
      server_double(state: 'active',
        public_ip_address: '10.100.1.2')
    end

    context 'and VM does not exist' do
      it 'creates missing VM' do
        expect {
          subject.execute
        }.to change { Atmosphere::VirtualMachine.count }.by(1)
      end

      it 'sets VMs details' do
        subject.execute

        expect(updated_vm).to vm_fog_data_equals(server, vmt)
      end
    end

    context 'and VM exists' do
      let!(:vm) do
        create(:virtual_machine,
               id_at_site: 'id_at_site',
               state: :build,
               name: 'old_name',
               source_template: vmt,
               compute_site: cs,
               created_at: old_vm_creation_time)
      end

      it 'reuses existing VM' do
        expect {
          subject.execute
        }.to change { Atmosphere::VirtualMachine.count }.by(0)
      end

      it 'updates VMs details' do
        subject.execute

        expect(updated_vm).to vm_fog_data_equals(server, vmt)
      end
    end

    it 'sets IP address' do
      subject.execute

      expect(updated_vm.ip).to eq '10.100.1.2'
    end
  end

  context 'when only private IP address' do
    let(:server) { server_double_with_priv_ip }

    it 'sets private VM ip' do
      subject.execute

      expect(updated_vm.ip).to eq '10.100.2.3'
    end
  end

  context 'when name is nil' do
    let(:server) do
      d = server_double(state: 'build')
      allow(d).to receive(:name).and_return(nil)
      d
    end

    it 'sets default VM name' do
      subject.execute

      expect(updated_vm.name).to eq "[unnamed]"
    end
  end

  context 'when error VM on cloud' do
    let(:server) do
      server_double(state: 'error',
        public_ip_address: '10.100.1.2')
    end

    it 'sets IP address' do
      subject.execute

      expect(updated_vm.ip).to eq '10.100.1.2'
    end
  end

  context 'when build VM on cloud' do
    let(:server) do
      server_double(state: 'build',
        public_ip_address: '10.100.1.2')
    end

    it 'does not set IP address' do
      subject.execute

      expect(updated_vm.ip).to be_nil
    end
  end

  context 'when VM created 1s before' do
    let(:server) { server_double(state: 'build', created: Time.now) }

    it 'does not update VM data' do
      expect {
        subject.execute
      }.to change { Atmosphere::VirtualMachine.count }.by(0)
    end
  end

  context 'cloud client supports updated field' do
    let(:server) do
      server_double(
        state: 'active',
        created: 2.hours.ago,
        public_ip_address: '1.2.3.4'
      )
    end
    let(:vm_update_at) { Time.new(2014, 6, 6, 14, 41, 2) }

    it 'updates VM IP if vm.updated_at_site is nil' do
      vm = create(:virtual_machine,
                  updated_at_site: nil,
                  id_at_site: 'id_at_site',
                  ip: nil,
                  compute_site: cs,
                  created_at: old_vm_creation_time)
      allow(server).to receive(:updated).and_return(vm_update_at)

      Atmosphere::VmUpdater.new(cs, server, updater_class).execute
      vm.reload

      expect(vm.ip).to eq '1.2.3.4'
    end

    it 'updates VM if server.updated > vm.updated_at_site' do
      vm = create(:virtual_machine,
                  updated_at_site: vm_update_at,
                  id_at_site: 'id_at_site',
                  ip: nil,
                  compute_site: cs,
                  created_at: old_vm_creation_time)
      allow(server).to receive(:updated).and_return(vm_update_at + 1)

      Atmosphere::VmUpdater.new(cs, server, updater_class).execute
      vm.reload

      expect(vm.ip).to eq '1.2.3.4'
    end

    it 'does not update VM IP if server.updated_at_site < vm.updated_at' do
      vm = create(:virtual_machine,
                  updated_at_site: vm_update_at,
                  id_at_site: 'id_at_site',
                  ip: nil,
                  compute_site: cs)
      allow(server).to receive(:updated).and_return(vm_update_at - 1)

      Atmosphere::VmUpdater.new(cs, server, updater_class).execute
      vm.reload

      expect(vm.ip).to be_nil
    end
  end

  def server_double(options)
    double(
      id: 'id_at_site',
      image_id: 'vmt_id_at_site',
      name: 'name',
      updated: Time.now,
      created: options[:created] || 5.seconds.ago,
      state: options[:state] || nil,
      flavor: options[:flavor] || {'id' => '1'},
      task_state: options[:task_state] || nil,
      public_ip_address: options[:public_ip_address] || nil,
      addresses: options[:public_ip_address] || nil
    )
  end

  def server_double_with_priv_ip(options={})
    double(
      id: 'id_at_site',
      image_id: 'vmt_id_at_site',
      name: 'name',
      updated: Time.now,
      created: options[:created] || 5.seconds.ago,
      state: 'active',
      flavor: options[:flavor] || {'id' => '1'},
      task_state: nil,
      public_ip_address: nil,
      addresses: {'private' => [ {'addr' => '10.100.2.3'} ]}
    )
  end

  def old_vm_creation_time
    (Atmosphere.childhood_age.seconds + 1).ago
  end
end
