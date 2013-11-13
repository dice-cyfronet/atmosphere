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

  describe 'DNAT registration' do
    it 'is performed after IP was changed and is not blank' do
      expect(WranglerRegistrarWorker).to receive(:perform_async)
      vm = create(:virtual_machine)
      vm.ip = priv_ip
      vm.save
    end

    context 'is not performed' do
      before do
        expect(WranglerRegistrarWorker).to_not receive(:perform_async)
      end

      it 'is not performed when attribute other than ip is updated' do
        vm = create(:virtual_machine)
        vm.name = 'so much changed'
        vm.save
      end

      it 'is not performed when ip is changed to blank' do
        vm = create(:virtual_machine, ip: priv_ip)
        vm.ip = nil
        vm.save
      end
    end
  end

  describe 'DNAT unregistration' do

    let(:vm) { create(:virtual_machine, ip: priv_ip) }
    let(:vm_ipless) { create(:virtual_machine) }

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
      it 'is performed after not blank IP was changed' do
        vm.ip = '8.8.8.8'
        vm.save
      end

      it 'is performed after VM is destroyed if IP was not blank' do
        vm.destroy
      end
    end

    context 'is not performed' do

      
      before do
        expect(WranglerEraserWorker).to_not receive(:perform_async)
      end

      it 'is not performed after blank IP was changed' do
        vm_ipless.ip = '8.8.8.8'
        vm_ipless.save
      end

      it 'is not performed after VM with blank IP was destroyed' do
        vm_ipless.destroy
      end
    
    end
    
  end
end
