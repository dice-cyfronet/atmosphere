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

  expect_it { to have_many(:port_mappings).dependent(:destroy) }

  describe 'proxy conf generation' do

    let(:generator) { double }
    before do
      ProxyConfWorker.stub(:new).and_return(generator)
    end

    let(:cs) { create(:compute_site) }
    let(:vm) { create(:virtual_machine, compute_site: cs) }

    context 'is performed' do

      before do
        expect(generator).to receive(:perform).with(cs.id)
      end

      it 'after IP is updated' do
        vm.ip = '1.1.1.1'
        vm.save
      end

      it 'after VM is created with IP filled' do
        create(:virtual_machine, ip: '1.1.1.1', compute_site: cs)
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
end
