require 'spec_helper'
require 'zabbix'

describe VmUpdater do
  let(:cs)  { create(:compute_site) }
  let!(:flavor) { create(:virtual_machine_flavor, compute_site: cs) }
  let(:vmt) { create(:virtual_machine_template, compute_site: cs) }

  let(:updater) { double('updater', update: true) }
  let(:updater_class) { double('updater_class', new: updater) }

  let(:updated_vm) { VirtualMachine.find_by(id_at_site: 'id_at_site') }

  before do
    VirtualMachineTemplate.stub(:find_by)
      .with(compute_site: cs, id_at_site: "vmt_id_at_site")
        .and_return(vmt)
    Zabbix.stub(:register_host).and_return 1
    Zabbix.stub(:unregister_host)
    Zabbix.stub(:host_metrics)
  end

  subject { VmUpdater.new(cs, server, updater_class) }

  describe 'VM states' do
    context "when task state equals to image_snapshot" do
      let(:server) do
        server_double(state: 'active',
                      task_state: 'image_snapshot',
                      flavor: {'id' => "1"})
      end

      subject { VmUpdater.new(cs, server, updater_class) }

      it 'sets "saving" state' do
        vm = subject.update
        expect(vm.state).to eq 'saving'
      end
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
                      compute_site: cs)

        vm.saved_templates << vmt
      end

      subject { VmUpdater.new(cs, server, updater_class) }

      it 'sets "saving" state' do
        vm = subject.update
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
        vm = create(:virtual_machine, id_at_site: 'id_at_site', compute_site: cs)
        appl1 = create(:appliance, virtual_machines: [vm])
        appl2 = create(:appliance, virtual_machines: [vm])
        appl_updater = double

        expect(updater_class).to receive(:new).with(appl1).and_return(appl_updater)
        expect(updater_class).to receive(:new).with(appl2).and_return(appl_updater)
        expect(appl_updater).to receive(:update).twice

        subject.update
      end

      it 'does not invoke updater when ip not changed' do
        vm = create(:virtual_machine,
          id_at_site: 'id_at_site',
          compute_site: cs, ip: '10.100.1.2')
        create(:appliance, virtual_machines: [vm])

        expect(updater).to_not receive(:update)

        subject.update
      end

      it 'does not invoke updater when no vm appliances' do
        create(:virtual_machine, id_at_site: 'id_at_site', compute_site: cs)

        expect(updater).to_not receive(:update)

        subject.update
      end

      it 'invokes updater when VM with IP changed state to active' do
        vm = create(:virtual_machine,
                id_at_site: 'id_at_site',
                ip: '10.100.1.2',
                compute_site: cs,
                state: :shutoff)
        appl1 = create(:appliance, virtual_machines: [vm])

        expect(updater).to receive(:update)

        subject.update
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

        VmUpdater.new(cs, server, updater_class).update
      end
    end

    context 'when other than active state' do

      let(:server) do
        server_double(state: 'error',
          public_ip_address: '10.100.1.2')
      end

      it 'invokes updater when state changed to other' do
        vm = create(:virtual_machine,
          id_at_site: 'id_at_site', state: :active,
          compute_site: cs, ip: '10.100.1.2')
        appl = create(:appliance, virtual_machines: [vm])
        appl_updater = double

        expect(updater_class).to receive(:new).with(appl).and_return(appl_updater)
        expect(appl_updater).to receive(:update).once

        subject.update
      end

      it 'does not invoke update when state changed to !active' do
        create(:virtual_machine,
          id_at_site: 'id_at_site',
          state: :build, compute_site: cs)

        expect(updater).to_not receive(:update)

        subject.update
      end

      it 'does not invoke updater even when ip changed' do
        create(:virtual_machine,
          id_at_site: 'id_at_site',
          ip: '10.100.1.3',
          state: :build, compute_site: cs)

        expect(updater).to_not receive(:update)

        subject.update
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
          subject.update
        }.to change { VirtualMachine.count }.by(1)
      end

      it 'sets VMs details' do
        subject.update

        expect(updated_vm).to vm_fog_data_equals(server, vmt)
      end
    end

    context 'and VM exists' do
      let!(:vm) do
        create(:virtual_machine, id_at_site: 'id_at_site', state: :build, name: 'old_name', source_template: vmt, compute_site: cs)
      end

      it 'reuses existing VM' do
        expect {
          subject.update
        }.to change { VirtualMachine.count }.by(0)
      end

      it 'updates VMs details' do
        subject.update

        expect(updated_vm).to vm_fog_data_equals(server, vmt)
      end
    end

    it 'sets IP address' do
      subject.update

      expect(updated_vm.ip).to eq '10.100.1.2'
    end
  end

  context 'when only private IP address' do
    let(:server) { server_double_with_priv_ip }

    it 'sets private VM ip' do
      subject.update

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
      subject.update

      expect(updated_vm.name).to eq "[unnamed]"
    end
  end

  context 'when error VM on cloud' do
    let(:server) do
      server_double(state: 'error',
        public_ip_address: '10.100.1.2')
    end

    it 'sets IP address' do
      subject.update

      expect(updated_vm.ip).to eq '10.100.1.2'
    end
  end

  context 'when build VM on cloud' do
    let(:server) do
      server_double(state: 'build',
        public_ip_address: '10.100.1.2')
    end

    it 'does not set IP address' do
      subject.update

      expect(updated_vm.ip).to be_nil
    end
  end

  context 'when VM created 1s before' do
    let(:server) { server_double(state: 'build', created: Time.now) }

    it 'does not update VM data' do
      expect {
        subject.update
      }.to change { VirtualMachine.count }.by(0)
    end
  end

  def server_double(options)
    double(
      id: 'id_at_site',
      image_id: 'vmt_id_at_site',
      name: 'name',
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
      created: options[:created] || 5.seconds.ago,
      state: 'active',
      flavor: options[:flavor] || {'id' => '1'},
      task_state: nil,
      public_ip_address: nil,
      addresses: {'private' => [ {'addr' => '10.100.2.3'} ]}
    )
  end
end