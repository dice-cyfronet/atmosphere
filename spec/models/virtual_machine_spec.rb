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

  let(:generator) { double }
  before do
    ProxyConfWorker.stub(:new).and_return(generator)
  end

  let(:registrar) { double('registrar worker')}
  before do
    WranglerRegistrarWorker.stub(:new).and_return registrar
  end

  let(:eraser) { double('eraser worker')}
  before do
    WranglerEraserWorker.stub(:new).and_return eraser
  end

  PRIV_IP = '10.1.1.16'

  expect_it { to have_many(:port_mappings).dependent(:destroy) }

  describe 'proxy conf generation' do

    

    let(:cs) { create(:compute_site) }
    let(:vm) { create(:virtual_machine, compute_site: cs) }

    context 'is performed' do

      before do
        expect(generator).to receive(:perform).with(cs.id)
        allow(registrar).to receive(:async_perform)
        allow(eraser).to receive(:async_perform)
      end

      it 'after IP is updated' do
        vm.ip = PRIV_IP
        vm.save
      end

      it 'after VM is created with IP filled' do
        create(:virtual_machine, ip: PRIV_IP, compute_site: cs)
      end

      it 'after VM is destroyed' do
        # just simulate VM deletion, no deletion on real cloud
        vm.destroy(false)
      end
    end

    context 'is not performed' do
      before do
        expect(generator).to_not receive(:perform)
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

    before do
      allow(generator).to receive(:perform)
    end
    

    it 'is performed after IP was changed and is not blank' do
      expect(registrar).to receive(:async_perform)
      vm = create(:virtual_machine)
      vm.ip = PRIV_IP
      vm.save
    end

    it 'is not performed when attribute other than ip is updated' do
      expect(registrar).to_not receive(:async_perform)
      vm = create(:virtual_machine)
      vm.name = 'so much changed'
      vm.save
    end

    it 'is not performed when ip is changed to blank' do
      expect(registrar).to_not receive(:async_perform)
      vm = create(:virtual_machine, ip: PRIV_IP)
      vm.ip = nil
      vm.save
    end

  end

  describe 'DNAT unregistration' do

    before do
      allow(generator).to receive(:perform)
    end

    it 'is performed after not blank IP was changed'

    it 'is not performed after blank IP was changed'

    it 'is not performed after VM with blank IP was destroyed'

    it 'is performed after VM is destroyed if IP was not blank' do
      expect(eraser).to receive(:async_perform)
      create(:virtual_machine, ip: PRIV_IP).destroy
    end
    
  end

end
