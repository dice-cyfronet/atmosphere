# == Schema Information
#
# Table name: virtual_machine_templates
#
#  id                 :integer          not null, primary key
#  id_at_site         :string(255)      not null
#  name               :string(255)      not null
#  state              :string(255)      not null
#  compute_site_id    :integer          not null
#  virtual_machine_id :integer
#  appliance_type_id  :integer
#  created_at         :datetime
#  updated_at         :datetime
#

require 'spec_helper'

describe VirtualMachineTemplate do

  before do
    Fog.mock!
  end

  expect_it { to ensure_inclusion_of(:state).in_array(%w(active deleted error saving queued killed pending_delete)) }

  context 'state is updated' do
    let!(:vm) { create(:virtual_machine) }
    subject { create(:virtual_machine_template, source_vm: vm, state: :saving) }
    let(:cc_mock) { double('cloud client mock') }
    let(:servers_mock) { double('servers') }
    before do
      Air.stub(:get_cloud_client).and_return(cc_mock)
      cc_mock.stub(:servers).and_return(servers_mock)
    end

    context 'active' do
      it 'sets source vm to nil' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :active)
        expect(subject.source_vm).to be_nil
      end

      it 'destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :active) }.to change { VirtualMachine.count}.by(-1)
      end

      it 'destroys vm in cloud if it does not have an appliance associated' do
        expect(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :active)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect(servers_mock).to_not receive(:destroy)
        subject.update_attribute(:state, :active)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect { subject.update_attribute(:state, :active) }.to_not change { VirtualMachine.count }
      end

    end

    context 'error' do
      it 'sets source vm to nil' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :error)
        expect(subject.source_vm).to be_nil
      end

      it 'destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :error) }.to change { VirtualMachine.count}.by(-1)
      end

      it 'destroys vm in cloud if it does not have an appliance associated' do
        expect(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :error)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect(servers_mock).to_not receive(:destroy)
        subject.update_attribute(:state, :error)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect { subject.update_attribute(:state, :error) }.to_not change { VirtualMachine.count }
      end
    end

    context 'saving' do
      it 'does not set source vm to nil' do
        subject.update_attribute(:state, :saving)
        expect(subject.source_vm).to eq vm
      end

      it 'does not destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :saving) }.to_not change { VirtualMachine.count}
      end

      it 'does not destroy vm in cloud if it does not have an appliance associated' do
        expect(servers_mock).to_not receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :saving)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect(servers_mock).to_not receive(:destroy)
        subject.update_attribute(:state, :saving)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect { subject.update_attribute(:state, :saving) }.to_not change { VirtualMachine.count }
      end
    end

  end

end
