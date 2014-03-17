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
#

require 'spec_helper'

describe VirtualMachine do

  before {
    Fog.mock! 
    Zabbix.stub(:register_host).and_return 1
    Zabbix.stub(:unregister_host)
    Zabbix.stub(:host_metrics)
  }

  let(:priv_ip) { '10.1.1.16' }
  let(:priv_ip_2) { '10.1.1.22' }
  let(:public_ip) { '149.156.10.145' }
  let(:public_port) { 23457 }
  let(:cs) { create(:openstack_with_flavors) }
  let(:appliance) { create(:appliance) }
  let(:vm) { create(:virtual_machine, compute_site: cs, managed_by_atmosphere: true) }
  let(:vm_ipless) { create(:virtual_machine, appliances: [appliance]) }
  let(:external_vm) { create(:virtual_machine, compute_site: cs, managed_by_atmosphere: false) }
  let(:default_flavor) { cs.virtual_machine_flavors.first }

  expect_it { to have_many(:port_mappings).dependent(:delete_all) }
  expect_it { to ensure_inclusion_of(:state).in_array(%w(active build deleted error hard_reboot password reboot rebuild rescue resize revert_resize shutoff suspended unknown verify_resize saving)) }

  context 'destruction' do
    let(:cc_mock) { double('cloud client mock') }
    let(:servers_mock) { double('servers') }
    before do
      cc_mock.stub(:servers).and_return(servers_mock)
    end

    it 'is not performed if it is being saved as template' do
      create(:virtual_machine_template, source_vm: vm, state: :saving)
      expect(servers_mock).to_not receive(:destroy)
      vm.compute_site.stub(:cloud_client).and_return(cc_mock)
      vm.destroy(true)
    end

    it 'is performed if vm does not have saved templates' do
      expect(servers_mock).to receive(:destroy).with(vm.id_at_site)
      vm.compute_site.stub(:cloud_client).and_return(cc_mock)
      vm.destroy(true)
    end

    it 'does not allow to destroy not managed virtual machine' do
      external_vm.compute_site.stub(:cloud_client).and_return(cc_mock)
      expect(servers_mock).to_not receive(:destroy)

      external_vm.destroy(true)

      expect(external_vm.errors).not_to be_empty
    end
  end

  context 'zabbix' do

    it 'registers vm after IP was changed from blank to non blank' do
      vm_ipless = create(:virtual_machine, appliances: [appliance], managed_by_atmosphere: true)
      expect(vm_ipless).to receive(:register_in_zabbix)
      expect(vm_ipless).not_to receive(:unregister_in_zabbix)
      vm_ipless.ip = priv_ip
      vm_ipless.save
    end

    it 'unregisters and registeres after IP was changed from non blank to non blank and zabbix_host_id was not blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true, zabbix_host_id: 1)
      expect(vm).to receive(:unregister_from_zabbix).ordered
      expect(vm).to receive(:register_in_zabbix).ordered
      vm.ip = priv_ip_2
      vm.save
    end

    it 'registeres after IP was changed from non blank to non blank but zabbix_host_id was blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true)
      expect(vm).to_not receive(:unregister_from_zabbix)
      expect(vm).to receive(:register_in_zabbix)
      vm.ip = priv_ip_2
      vm.save
    end

    it 'unregisters vm after non-blank IP was changed and is blank and zabbix_host_id was not blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true, zabbix_host_id: 1)
      expect(vm).to receive(:unregister_from_zabbix)
      expect(vm).to_not receive(:register_in_zabbix)        
      vm.ip = nil
      vm.save
    end

    it 'does not unregister vm after non-blank IP was changed and is blank but zabbix_host_id is blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true)
      expect(vm).to_not receive(:unregister_from_zabbix)
      expect(vm).to_not receive(:register_in_zabbix)        
      vm.ip = nil
      vm.save
    end

    it 'unregisters vm before vm is destroyed if ip and zabbix_host_id are not blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true, zabbix_host_id: 1)
      expect(vm).to receive(:unregister_from_zabbix)
      expect(vm).to_not receive(:register_in_zabbix)
      vm.destroy(false)
    end

    it 'does nothing before vm is destroyed if ip is present but zabbix_host_id is blank' do
      vm = create(:virtual_machine, appliances: [appliance], ip: priv_ip, managed_by_atmosphere: true)
      expect(vm).to_not receive(:unregister_from_zabbix)
      expect(vm).to_not receive(:register_in_zabbix)
      vm.destroy(false)
    end

    it 'does nothing before vm is destroyed if ip was blank' do
      vm_ipless = create(:virtual_machine, appliances: [appliance], managed_by_atmosphere: true)
      vm_ipless.stub(:destroy)
      expect(vm_ipless).not_to receive(:register_in_zabbix)
      expect(vm_ipless).not_to receive(:unregister_in_zabbix)
      vm_ipless.destroy
    end

  end

  context 'DNAT' do
    let(:vm) { create(:virtual_machine, ip: priv_ip, appliances: [appliance]) }
    let(:priv_port) { 8888 }
    let(:priv_port_2) { 7070 }
    let!(:pmt_1) { create(:port_mapping_template, target_port: priv_port, appliance_type: vm_ipless.appliance_type, application_protocol: :none) }
    let(:wrg) { double('wrangler') }

    before do
      vm.compute_site.stub(:dnat_client).and_return(wrg)
      vm_ipless.compute_site.stub(:dnat_client).and_return(wrg)
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
        expect { vm_ipless.save }.to change {PortMapping.count}.by 1
      end

    end

    describe 'unregistration' do

      before do
        # we are testing dnat unregistration not cloud action, thus we can mock it
        servers_double = double
        vm.compute_site.cloud_client.stub(:servers).and_return(servers_double)
        vm_ipless.compute_site.cloud_client.stub(:servers).and_return(servers_double)
        allow(servers_double).to receive(:destroy)
      end

      context 'is performed' do
        context 'wrangler service is called' do
          before do
            expect(wrg).to receive(:remove_dnat_for_vm).with(vm)
          end

          it 'after VM is destroyed if IP was not blank' do
            vm.destroy
          end

          it 'if VM ip was updated from non-blank value to blank' do
            vm.ip = nil
            vm.save
          end
        end
        context 'removes port mappings from DB' do
          before do
            allow(wrg).to receive(:remove_dnat_for_vm).with(vm).and_return(true)
          end

          it 'after VM is destroyed if IP was not blank' do
            create(:port_mapping, virtual_machine: vm)
            create(:port_mapping, virtual_machine: vm)
            expect { vm.destroy }.to change {PortMapping.count}.by -2
          end

          it 'if VM ip was updated from non-blank value to blank' do
            vm.ip = nil
            create(:port_mapping, virtual_machine: vm)
            create(:port_mapping, virtual_machine: vm)
            expect { vm.save }.to change {PortMapping.count}.by -2
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
          expect(wrg).to receive(:remove_dnat_for_vm).with(vm)
          vm.ip = nil
          vm.save
      end

      it 'adds dnat if blank IP was changed to not blank' do
          expect(wrg).to receive(:add_dnat_for_vm).with(vm_ipless, [pmt_1]).and_return([])
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
          expect(wrg).to receive(:remove_dnat_for_vm).with(vm)
          expect(wrg).to receive(:add_dnat_for_vm).with(vm, [pmt_1]).and_return([])
          vm.ip = '8.8.8.8'
          vm.save
        end
      end
    end

  end

  context 'initital configuration' do



  end


  context 'instantiation' do

    VM_NAME = 'key-tester'

    let(:cloud_client) { double('cloud client') }
    let(:servers) { double('servers') }
    let(:server) { double('server') }
    let(:appl_dev_mode) { create(:appl_dev_mode) }

    before do
      opt = double('optimizer')
      allow(opt).to receive (:run)
      Optimizer.stub(:instance).and_return(opt)
      Fog::Compute.stub(:new).and_return(cloud_client)
    end

    let(:init_conf) { create(:appliance_configuration_instance) }
    let(:tmpl) { create(:virtual_machine_template) }

    context 'flavor' do

      it 'is included in request to cloud' do
        allow(cloud_client).to receive(:servers).and_return(servers)
        server_params = {flavor_ref: default_flavor.id_at_site, flavor_id: default_flavor.id_at_site, name: VM_NAME, image_ref: tmpl.id_at_site, image_id: tmpl.id_at_site, user_data: appl_dev_mode.appliance_configuration_instance.payload}
        expect(servers).to receive(:create).with(server_params).and_return(server)
        expect(server).to receive(:id).twice.and_return 1
        create(:virtual_machine, compute_site: cs, appliances: [appl_dev_mode], id_at_site: nil, name: VM_NAME, source_template: tmpl, virtual_machine_flavor: default_flavor)
      end

    end

    context 'user key' do

      it 'imports user key to compute site' do
        allow(cloud_client).to receive(:servers).and_return(servers)
        allow(servers).to receive(:create).and_return(server)
        allow(server).to receive(:id).twice.and_return 1
        key = create(:user_key)
        expect(cloud_client).to receive(:import_key_pair).with(key.id_at_site, key.public_key)
        appl = create(:appl_dev_mode, user_key: key)
        create(:virtual_machine, compute_site: cs, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl)
      end

      it 'injects user key if key is defined' do
        expect(cloud_client).to receive(:servers).and_return(servers)
        allow(cloud_client).to receive(:import_key_pair)
        key = create(:user_key)
        appl = create(:appl_dev_mode, user_key: key)
        server_params = {flavor_ref: default_flavor.id_at_site, flavor_id: default_flavor.id_at_site, name: VM_NAME, image_ref: tmpl.id_at_site, image_id: tmpl.id_at_site, user_data: appl.appliance_configuration_instance.payload, key_name: key.id_at_site}
        expect(servers).to receive(:create).with(server_params).and_return(server)
        expect(server).to receive(:id).twice.and_return 1
        create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl, virtual_machine_flavor: default_flavor)
      end

      it 'does not inject user key if key is undefined' do
        expect(cloud_client).to receive(:servers).and_return(servers)
        appl = create(:appl_dev_mode)
        server_params = {flavor_ref: default_flavor.id_at_site, flavor_id: default_flavor.id_at_site, name: VM_NAME, image_ref: tmpl.id_at_site, image_id: tmpl.id_at_site, user_data: appl.appliance_configuration_instance.payload}
        expect(servers).to receive(:create).with(server_params).and_return(server)
        expect(server).to receive(:id).twice.and_return 1
        create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl, virtual_machine_flavor: default_flavor)
      end

    end

    context 'setting name in AWS' do
      let(:aws) {create(:amazon_with_flavors)}
      let(:tmpl_at_aws) {create(:virtual_machine_template, compute_site: aws)}

      it 'sets the Name tag' do
        allow(cloud_client).to receive(:servers).and_return(servers)
        expect(cloud_client).to receive(:create_tags).with(1,{'Name' => VM_NAME})
        server_params = {flavor_ref: default_flavor.id_at_site, flavor_id: default_flavor.id_at_site, name: VM_NAME, image_ref: tmpl_at_aws.id_at_site, image_id: tmpl_at_aws.id_at_site}
        allow(servers).to receive(:create).and_return(server)
        allow(server).to receive(:id).exactly(3).and_return 1
        create(:virtual_machine, appliances: [appl_dev_mode], id_at_site: nil, name: VM_NAME, source_template: tmpl_at_aws, virtual_machine_flavor: default_flavor)
      end
    end

    context 'initial configuration' do

      it 'is injected payload not blank' do
        expect(cloud_client).to receive(:servers).and_return(servers)
        server_params = {flavor_ref: default_flavor.id_at_site, flavor_id: default_flavor.id_at_site, name: VM_NAME, image_ref: tmpl.id_at_site, image_id: tmpl.id_at_site, user_data: appl_dev_mode.appliance_configuration_instance.payload}
        expect(servers).to receive(:create).with(server_params).and_return(server)
        expect(server).to receive(:id).twice.and_return 1
        create(:virtual_machine, appliances: [appl_dev_mode], id_at_site: nil, name: VM_NAME, source_template: tmpl, virtual_machine_flavor: default_flavor)
      end

      it 'is not injected if payload is blank' do
        expect(cloud_client).to receive(:servers).and_return(servers)
        appl = create(:appl_dev_mode, appliance_configuration_instance: ApplianceConfigurationInstance.create())
        server_params = {flavor_ref: default_flavor.id_at_site, flavor_id: default_flavor.id_at_site, name: VM_NAME, image_ref: tmpl.id_at_site, image_id: tmpl.id_at_site}
        expect(servers).to receive(:create).with(server_params).and_return(server)
        expect(server).to receive(:id).twice.and_return 1
        create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl, virtual_machine_flavor: default_flavor)
      end

    end
  end

  context 'creating new virtual machine' do
    let(:appl) { create(:appliance) }
    let(:tmpl) { create(:virtual_machine_template) }
    let(:vm) { create(:virtual_machine, compute_site: cs, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl) }
    let(:external_vm) { create(:virtual_machine, compute_site: cs, appliances: [appl], id_at_site: 'vm_id', name: VM_NAME, source_template: tmpl) }


    it 'sets managed_by_atmosphere to true for spawned VM' do
      expect(vm.managed_by_atmosphere).to be_true
    end

    it 'sets managed_by_atmosphere to false for external VM' do
      expect(external_vm.managed_by_atmosphere).to be_false
    end
  end

  context '::manageable' do
    let!(:vm) { create(:virtual_machine, managed_by_atmosphere: true)  }

    before do
      create(:virtual_machine)
    end

    it 'returns only VMs manageable by atmosphere' do
      vms = VirtualMachine.manageable

      expect(vms.count).to eq 1
      expect(vms[0]).to eq vm
    end
  end
end
