# == Schema Information
#
# Table name: virtual_machines
#
#  id                          :integer          not null, primary key
#  id_at_site                  :string(255)      not null
#  name                        :string(255)      not null
#  state                       :string(255)      not null
#  ip                          :string(255)
#  compute_site_id             :integer          not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#

require 'spec_helper'

describe VirtualMachine do

  before { Fog.mock! }

  let(:priv_ip) { '10.1.1.16' }

  expect_it { to have_many(:port_mappings).dependent(:destroy) }

  describe 'proxy conf generation' do
    let(:cs) { create(:compute_site) }
    let(:vm) { create(:virtual_machine, compute_site: cs) }

    context 'is performed' do

      before do
        expect(ProxyConfWorker).to receive(:regeneration_required).with(cs)
        allow(WranglerRegistrarWorker).to receive(:perform_async)
        allow(WranglerEraserWorker).to receive(:perform_async)
      end

      it 'after IP is updated' do
        vm.ip = priv_ip
        vm.save
      end

      it 'after VM is created with IP filled' do
        create(:virtual_machine, ip: priv_ip, compute_site: cs)
      end

      it 'after VM is destroyed' do
        # just simulate VM deletion, no deletion on real cloud
        vm.destroy(false)
      end
    end

    context 'is not performed' do
      before do
        expect(ProxyConfWorker).to_not receive(:regeneration_required)
      end

      it 'after VM is created with empty IP' do
        create(:virtual_machine)
      end

      it 'after VM attribute other than IP is changed' do
        vm.name = 'new_name'
        vm.save
      end
    end
  end

  context 'DNAT' do
    let(:vm_ipless) { create(:virtual_machine) }
    let(:vm) { create(:virtual_machine, ip: priv_ip) }

    context 'registration' do
      it 'is performed after IP was changed and is not blank' do
        expect(WranglerRegistrarWorker).to receive(:perform_async)
        vm_ipless.ip = priv_ip
        vm_ipless.save
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
        before do
          expect(WranglerEraserWorker).to receive(:perform_async)
        end

        it 'after VM is destroyed if IP was not blank' do
          vm.destroy
        end

        it 'if VM ip was updated from non-blank value to blank' do
          vm.ip = nil
          vm.save
        end
      end

      context 'is not performed' do

        before do
          expect(WranglerEraserWorker).to_not receive(:perform_async)
        end

        it 'is not performed after VM with blank IP was destroyed' do
          vm_ipless.destroy
        end
      
      end
      
    end

    context 'regeneration' do
      context 'is not performed' do
        
        before do
          expect(WranglerRegeneratorWorker).to_not receive(:perform_async)
        end

        it 'after blank IP was changed' do
          vm_ipless.ip = '8.8.8.8'
          vm_ipless.save
        end

        it 'when attribute other than ip is updated' do
          vm = create(:virtual_machine)
          vm.name = 'so much changed'
          vm.save
        end

        it 'performed when ip is changed to blank' do
          vm = create(:virtual_machine, ip: priv_ip)
          vm.ip = nil
          vm.save
        end
      end

      context 'is performed' do
        it 'after not blank IP was changed' do
          expect(WranglerRegeneratorWorker).to receive(:perform_async)
          vm.ip = '8.8.8.8'
          vm.save
        end
      end
    end

    context 'update' do
      it 'creates DNAT update job' do
        expect(WranglerMappingUpdaterWorker).to receive(:perform_async)
        pmt = create(:port_mapping_template)
        vm.update_mapping(pmt)
      end
    end
  end

  context 'initital configuration' do



  end


  context 'injecting' do
  
    VM_NAME = 'key-tester'
    FLAVOR_REF = 1

    let(:cloud_client) { double('cloud client') }
    let(:servers) { double('servers') }
    let(:server) { double('server') }

    before do
      opt = double('optimizer')
      allow(opt).to receive (:run)
      Optimizer.stub(:instance).and_return(opt)
      Fog::Compute.stub(:new).and_return(cloud_client)
    end

    let(:init_conf) { create(:appliance_configuration_instance) }
    let(:tmpl) { create(:virtual_machine_template) }

    it 'imports user key to compute site' do
      allow(cloud_client).to receive(:servers).and_return(servers)
      allow(servers).to receive(:create).and_return(server)
      allow(server).to receive(:id).twice.and_return 1
      key = create(:user_key)
      expect(cloud_client).to receive(:import_key_pair).with(key.id_at_site, key.public_key)
      appl = create(:appl_dev_mode, user_key: key)
      create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl)
    end

    it 'injects user key if key is defined' do
      expect(cloud_client).to receive(:servers).and_return(servers)
      allow(cloud_client).to receive(:import_key_pair)
      key = create(:user_key)
      appl = create(:appl_dev_mode, user_key: key)
      server_params = {flavor_ref: FLAVOR_REF, name: VM_NAME, image_ref: tmpl.id_at_site, user_data: appl.appliance_configuration_instance.payload, key_name: key.id_at_site}
      expect(servers).to receive(:create).with(server_params).and_return(server)
      expect(server).to receive(:id).twice.and_return 1
      create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl)  
    end

    it 'does not inject user key if key is undefined' do
      expect(cloud_client).to receive(:servers).and_return(servers)
      appl = create(:appl_dev_mode)
      server_params = {flavor_ref: FLAVOR_REF, name: VM_NAME, image_ref: tmpl.id_at_site, user_data: appl.appliance_configuration_instance.payload}
      expect(servers).to receive(:create).with(server_params).and_return(server)
      expect(server).to receive(:id).twice.and_return 1
      create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl)
    end

    it 'injects initial configuration if payload not blank' do
      expect(cloud_client).to receive(:servers).and_return(servers)
      appl = create(:appl_dev_mode)
      server_params = {flavor_ref: FLAVOR_REF, name: VM_NAME, image_ref: tmpl.id_at_site, user_data: appl.appliance_configuration_instance.payload}
      expect(servers).to receive(:create).with(server_params).and_return(server)
      expect(server).to receive(:id).twice.and_return 1
      create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl)
    end

    it 'does not inject initial configuration if payload is blank' do
      expect(cloud_client).to receive(:servers).and_return(servers)
      appl = create(:appl_dev_mode, appliance_configuration_instance: ApplianceConfigurationInstance.create())
      server_params = {flavor_ref: FLAVOR_REF, name: VM_NAME, image_ref: tmpl.id_at_site}
      expect(servers).to receive(:create).with(server_params).and_return(server)
      expect(server).to receive(:id).twice.and_return 1
      create(:virtual_machine, appliances: [appl], id_at_site: nil, name: VM_NAME, source_template: tmpl)
    end

  end
end
