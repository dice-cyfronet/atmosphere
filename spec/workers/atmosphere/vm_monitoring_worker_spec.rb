require 'spec_helper'

describe Atmosphere::VmMonitoringWorker do
  let(:vm_updater_class) { double }
  let(:vm_destroyer_class) { double('destroyer') }

  before {
    Fog.mock!
  }

  subject { Atmosphere::VmMonitoringWorker.new(vm_updater_class, vm_destroyer_class) }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end

    it { should be_retryable false }
    it { should be_processed_in :monitoring }
  end

  context 'when updating VMs' do
    let(:cloud_client) { double }
    let(:cs) { double('cs', cloud_client: cloud_client) }

    before do
      allow(Atmosphere::ComputeSite)
        .to receive(:find).with(1).and_return(cs)
    end

    context 'and cloud client returns information about VMs' do
      it 'updates VMs' do
        updater1 = double
        updater2 = double
        allow(cloud_client).to receive(:servers).and_return(['1', '2'])
        allow(cs).to receive(:virtual_machines).and_return([])

        expect(updater1).to receive(:update).and_return('1')
        expect(vm_updater_class).to receive(:new).with(cs, '1').and_return(updater1)
        expect(updater2).to receive(:update).and_return('2')
        expect(vm_updater_class).to receive(:new).with(cs, '2').and_return(updater2)

        subject.perform(1)
      end

      it 'deletes only old VMs not found on compute site' do
        old_vm = double(old?: true)
        young_vm = double(old?: false)

        destroyer = double
        allow(cloud_client).to receive(:servers).and_return([])
        allow(cs).to receive(:virtual_machines).and_return([old_vm])

        expect(destroyer).to receive(:destroy).with(false)
        expect(vm_destroyer_class).to receive(:new)
          .with(old_vm).and_return(destroyer)
        expect(vm_destroyer_class).not_to receive(:new)
          .with(young_vm)

        subject.perform(1)
      end
    end

    context 'and fog error occurs' do
      let(:logger) { double }

      before do
        allow(Air). to receive(:monitoring_logger).and_return(logger)
        expect(logger).to receive(:error)
        allow(logger).to receive(:debug)

        allow(cloud_client).to receive(:servers).and_raise(Excon::Errors::Unauthorized.new 'error')
      end

      it 'logs error into rails logs' do
        subject.perform(1)
      end
    end
  end
end