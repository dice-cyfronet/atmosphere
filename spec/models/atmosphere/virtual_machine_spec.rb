# == Schema Information
#
# Table name: virtual_machines
#
#  id                          :integer          not null, primary key
#  id_at_site                  :string(255)      not null
#  name                        :string(255)      not null
#  state                       :string(255)      not null
#  ip                          :string(255)
#  managed_by_atmosphere       :boolean          default(FALSE), not null
#  compute_site_id             :integer          not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#  virtual_machine_flavor_id   :integer
#  monitoring_id               :integer
#

require 'rails_helper'
require_relative "../../shared_examples/childhoodable.rb"

describe Atmosphere::VirtualMachine do

  before {
    Fog.mock!
  }

  let(:priv_ip) { '10.1.1.16' }
  let(:priv_ip_2) { '10.1.1.22' }
  let(:public_ip) { '149.156.10.145' }
  let(:public_port) { 23457 }
  let(:t) { create(:openstack_with_flavors) }
  let(:appliance) { create(:appliance) }
  let(:vm) { create(:virtual_machine, tenant: t, managed_by_atmosphere: true) }
  let(:vm_ipless) { create(:virtual_machine, appliances: [appliance]) }
  let(:external_vm) { create(:virtual_machine, tenant: t, managed_by_atmosphere: false) }
  let(:default_flavor) { t.virtual_machine_flavors.first }

  it { should have_many(:port_mappings).dependent(:delete_all) }
  it { should validate_inclusion_of(:state).in_array(%w(active build deleted error hard_reboot password reboot rebuild rescue resize revert_resize shutoff suspended unknown verify_resize saving)) }

  context 'destruction' do
    let(:servers_mock) { double('servers') }
    let(:cc_mock) { double('cloud client mock', servers: servers_mock) }

    it 'is not performed if it is being saved as template' do
      create(:virtual_machine_template, source_vm: vm, state: :saving)
      allow(vm.tenant).to receive(:cloud_client).and_return(cc_mock)

      expect(servers_mock).to_not receive(:destroy)
      expect(Raven).to_not receive(:capture_message)
      allow(vm.tenant).to receive(:cloud_client).and_return(cc_mock)

      vm.destroy(true)
    end

    it 'is performed if vm does not have saved templates' do
      expect(servers_mock).to receive(:destroy).with(vm.id_at_site).and_return true
      expect(Raven).to_not receive(:capture_message)
      allow(vm.tenant).to receive(:cloud_client).and_return(cc_mock)

      vm.destroy(true)
    end

    it 'does not allow to destroy not managed virtual machine' do
      allow(external_vm.tenant).to receive(:cloud_client).and_return(cc_mock)
      expect(servers_mock).to_not receive(:destroy)
      expect(Raven).to_not receive(:capture_message)
      external_vm.destroy(true)

      expect(external_vm.errors).not_to be_empty
    end

    it 'does not report error to Raven if succeds to delete vm' do
      expect(servers_mock).to receive(:destroy).with(vm.id_at_site).and_return true
      expect(Raven).to_not receive(:capture_message)
      allow(vm.tenant).to receive(:cloud_client).and_return(cc_mock)
      vm.destroy(true)
    end

    it 'report error to Raven if fails to delete vm' do
      expect(servers_mock).to receive(:destroy).with(vm.id_at_site).and_return false
      expect(Raven).to receive(:capture_message).with(
        "Error destroying VM in cloud",
        {
          logger: 'error',
          extra: {
            id_at_site: vm.id_at_site,
            tenant_id: vm.tenant_id
          }
        }
      )
      allow(vm.tenant).to receive(:cloud_client).and_return(cc_mock)
      vm.destroy(true)
    end

    it 'ignores when VM does not exist on OpenStack' do
      delete_with_success_when_exception(Fog::Compute::OpenStack::NotFound)
    end

    it 'ignores when VM does not exist on Amazon' do
      delete_with_success_when_exception(Fog::Compute::AWS::NotFound)
    end

    def delete_with_success_when_exception(e)
      allow(vm.tenant).
        to receive(:cloud_client).
        and_return(cc_mock)

      allow(servers_mock).
        to receive(:destroy).
        with(vm.id_at_site).
        and_raise(e)

      expect { vm.destroy }.
        to change { Atmosphere::VirtualMachine.count }.by(-1)
    end
  end

  context 'monitoring' do

    it 'registers vm after IP was changed from blank to non blank' do
      vm_ipless = create(:virtual_machine, appliances: [appliance], managed_by_atmosphere: true)
      expect(vm_ipless).to receive(:register_in_monitoring)
      expect(vm_ipless).not_to receive(:unregister_from_monitoring)
      vm_ipless.ip = priv_ip
      vm_ipless.save
    end

    it 'unregisters and registeres after IP was changed from non blank to non blank and monitoring_id was not blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true, monitoring_id: 1)
      expect(vm).to receive(:unregister_from_monitoring).ordered
      expect(vm).to receive(:register_in_monitoring).ordered
      vm.ip = priv_ip_2
      vm.save
    end

    it 'registers after IP was changed from non blank to non blank but monitoring_id was blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true)
      expect(vm).to_not receive(:unregister_from_monitoring)
      expect(vm).to receive(:register_in_monitoring)
      vm.ip = priv_ip_2
      vm.save
    end

    it 'unregisters vm after non-blank IP was changed and is blank and monitoring_id was not blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true, monitoring_id: 1)
      expect(vm).to receive(:unregister_from_monitoring)
      expect(vm).to_not receive(:register_in_monitoring)
      vm.ip = nil
      vm.save
    end

    it 'does not unregister vm after non-blank IP was changed and is blank but monitoring_id is blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true)
      expect(vm).to_not receive(:unregister_from_monitoring)
      expect(vm).to_not receive(:register_in_monitoring)
      vm.ip = nil
      vm.save
    end

    it 'unregisters vm before vm is destroyed if ip and monitoring_id are not blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true, monitoring_id: 1)
      expect(vm).to receive(:unregister_from_monitoring)
      expect(vm).to_not receive(:register_in_monitoring)
      vm.destroy(false)
    end

    it 'does nothing before vm is destroyed if ip is present but monitoring_id is blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true)
      expect(vm).to_not receive(:unregister_from_monitoring)
      expect(vm).to_not receive(:register_in_monitoring)
      vm.destroy(false)
    end

    it 'does nothing before vm is destroyed if ip was blank' do
      vm_ipless = create(:virtual_machine, appliances: [appliance], managed_by_atmosphere: true)
      allow(vm_ipless).to receive(:destroy)

      expect(vm_ipless).not_to receive(:register_in_monitoring)
      expect(vm_ipless).not_to receive(:unregister_from_monitoring)

      vm_ipless.destroy
    end
  end

  context 'DNAT' do
    let(:vm) { create(:virtual_machine,
                      ip: priv_ip,
                      appliances: [appliance],
                      managed_by_atmosphere: true) }
    let(:priv_port) { 8888 }
    let(:priv_port_2) { 7070 }
    let!(:pmt_1) { create(:port_mapping_template, target_port: priv_port, appliance_type: vm_ipless.appliance_type, application_protocol: :none) }
    let(:wrg) { double('wrangler') }

    before do
      allow(vm.tenant).to receive(:dnat_client).and_return(wrg)
      allow(vm_ipless.tenant).to receive(:dnat_client).and_return(wrg)
    end

    context 'registration' do
      it 'is performed after IP was changed and is not blank' do
        expect(wrg).to receive(:add_dnat_for_vm).with(vm_ipless, [pmt_1]).and_return([])
        vm_ipless.ip = priv_ip
        vm_ipless.save
      end

      it 'creates new port mapping after IP was changed and is not blank' do
        expect(wrg).to receive(:add_dnat_for_vm).with(vm_ipless, [pmt_1]).and_return([{port_mapping_template: pmt_1, virtual_machine: vm_ipless, public_ip: public_ip, source_port: public_port}])
        vm_ipless.ip = priv_ip
        expect { vm_ipless.save }.to change {Atmosphere::PortMapping.count}.by 1
      end
    end

    describe 'unregistration' do

      before do
        # we are testing dnat unregistration not cloud action, thus we can mock it
        servers_double = double
        allow(vm.tenant.cloud_client)
          .to receive(:servers).and_return(servers_double)
        allow(vm_ipless.tenant.cloud_client)
          .to receive(:servers).and_return(servers_double)
        allow(servers_double).to receive(:destroy)
      end

      context 'is performed' do
        context 'wrangler service is called' do
          before do
            expect(wrg).to receive(:remove).with(priv_ip)
          end

          it 'after VM is destroyed if IP was not blank' do
            vm.destroy
          end

          it 'if VM ip was updated from non-blank value to blank' do
            vm.ip = nil
            vm.save
          end

          it 'if VM ip was updated from non-blank value to non-blank' do
            allow(wrg).to receive(:add_dnat_for_vm).and_return([])
            vm.ip = priv_ip_2
            vm.save
          end
        end
        context 'removes port mappings from DB' do
          before do
            allow(wrg).to receive(:remove).and_return(true)
          end

          it 'after VM is destroyed if IP was not blank' do
            create(:port_mapping, virtual_machine: vm)
            create(:port_mapping, virtual_machine: vm)
            expect { vm.destroy }.to change {Atmosphere::PortMapping.count}.by -2
          end

          it 'if VM ip was updated from non-blank value to blank' do
            vm.ip = nil
            create(:port_mapping, virtual_machine: vm)
            create(:port_mapping, virtual_machine: vm)
            expect { vm.save }.to change {Atmosphere::PortMapping.count}.by -2
          end
        end
      end

      context 'is not performed' do

        it 'is not performed after VM with blank IP was destroyed' do
          vm_ipless.destroy
        end
      end
    end

    context 'regeneration' do

      it 'deletes dnat if ip is changed to blank' do
        old_ip = vm.ip
        expect(wrg).to receive(:remove).with(old_ip)
        vm.ip = nil
        vm.save
      end

      it 'adds dnat if blank IP was changed to not blank' do
        expect(wrg).to receive(:add_dnat_for_vm).
          with(vm_ipless, [pmt_1]).and_return([])
        vm_ipless.ip = '8.8.8.8'
        vm_ipless.save
      end

      context 'is not performed' do

        it 'when attribute other than ip is updated' do
          vm = create(:virtual_machine)
          vm.name = 'so much changed'
          vm.save
        end
      end

      context 'is performed' do
        it 'after not blank IP was changed' do
          old_ip = vm.ip
          expect(wrg).to receive(:remove).with(old_ip)
          expect(wrg).to receive(:add_dnat_for_vm).with(vm, [pmt_1]).and_return([])
          vm.ip = '8.8.8.8'
          vm.save
        end
      end
    end
  end

  context '::manageable' do
    let!(:vm) { create(:virtual_machine, managed_by_atmosphere: true)  }

    before do
      @nonmanaged = create(:virtual_machine)
    end

    it 'returns only VMs manageable by atmosphere' do
      vms = Atmosphere::VirtualMachine.manageable

      expect(vms.count).to eq 1
      expect(vms[0]).to eq vm
    end

    it 'allows destruction of managed machines only' do
      expect { @nonmanaged.destroy }.
        to change { Atmosphere::VirtualMachine.count }.by(0)
      expect { vm.destroy }.
        to change { Atmosphere::VirtualMachine.count }.by(-1)
    end
  end

  context '::monitorable' do
    let!(:vm) { create(:virtual_machine, ip: priv_ip) }
    let!(:managable_vm) do
      create(:virtual_machine, managed_by_atmosphere: true, ip: priv_ip_2)
    end
    let!(:monitorable_vm) do
      create(
        :virtual_machine,
        managed_by_atmosphere: true,
        monitoring_id: '1',
        ip: public_ip
      )
    end

    it 'returns only monitorable vms' do
      monitorable_vms = Atmosphere::VirtualMachine.monitorable

      expect(monitorable_vms.size).to eq 1
      expect(monitorable_vms[0]).to eq monitorable_vm
    end

  end

  it_behaves_like 'childhoodable'

  context 'cloud action' do
    let(:servers) { double }
    let(:server) { double }
    let(:id_at_site) { 'id_at_site' }
    let(:cloud_client) { double(servers: servers) }
    let(:vm) { create(:virtual_machine, id_at_site: id_at_site) }

    before do
      allow_any_instance_of(Atmosphere::Tenant)
        .to receive(:cloud_client).and_return(cloud_client)
      allow(servers).to receive(:get).with(id_at_site).and_return(server)
    end

    it 'sends reboot action to underlying tenant' do
      invoke_cloud_action(:reboot)
    end

    it 'changes state into "reboot" after reboot action' do
      change_state_after_action(:reboot, 'reboot')
    end

    it 'sends stop action to underlying tenant' do
      invoke_cloud_action(:stop)
    end

    it 'changes state into "shutoff" after stop action' do
      change_state_after_action(:stop, 'shutoff')
    end

    it 'sends pause action to underlying tenant' do
      invoke_cloud_action(:pause)
    end

    it 'changes state into "paused" after pause action' do
      change_state_after_action(:pause, 'paused')
    end

    it 'sends start action to underlying tenant' do
      invoke_cloud_action(:start)
    end

    it 'changes state into "active" after start action' do
      change_state_after_action(:start, 'active')
    end

    it 'skip second vm restart' do
      expect(server).
        to receive(:reboot).
        and_raise(Excon::Errors::Conflict.new('conflict'))

      vm.send(:reboot)
    end

    def invoke_cloud_action(action_name)
      expect(server).to receive(action_name)

      vm.send(action_name)
    end

    def change_state_after_action(action_name, new_state)
      allow(server).to receive(action_name).and_return(true)

      vm.send(action_name)
      vm.reload

      expect(vm.state).to eq new_state
    end
  end

  context '#unused' do
    it 'returns VMs not assigned to appliance' do
      vm = create(:virtual_machine,
                  managed_by_atmosphere: true)
      appl = create(:appliance)
      create(:virtual_machine,
             appliances: [appl],
             managed_by_atmosphere: true)

      unused_vms = Atmosphere::VirtualMachine.unused

      expect(unused_vms.count).to eq 1
      expect(unused_vms.first.id).to eq vm.id
    end

    it 'returns VMs not used to save VMT' do
      vm = create(:virtual_machine,
                  managed_by_atmosphere: true)
      vmt = create(:virtual_machine_template)
      create(:virtual_machine,
             saved_templates: [vmt],
             managed_by_atmosphere: true)

      unused_vms = Atmosphere::VirtualMachine.unused

      expect(unused_vms.count).to eq 1
      expect(unused_vms.first.id).to eq vm.id
    end
  end
end
