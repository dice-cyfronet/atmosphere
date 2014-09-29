require 'rails_helper'

describe VmLoadMonitoringWorker do

  before {
    Fog.mock!
  }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end

    it { should be_retryable false }
    it { should be_processed_in :monitoring }
  end

  context 'Zabbix' do
    it 'queries Zabbix for each vm with zabbix id that are managed by atmosphere' do
      vm1 = create(:virtual_machine, ip: '10.100.0.1', monitoring_id: 1, managed_by_atmosphere: true)
      vm2 = create(:virtual_machine, ip: '10.100.0.2', monitoring_id: 2, managed_by_atmosphere: true)
      vm3 = create(:virtual_machine, ip: '10.100.0.3', managed_by_atmosphere: true)
      vm4 = create(:virtual_machine, ip: '10.100.0.4', monitoring_id: 3)
      allow(VirtualMachine).to receive(:all).and_return [vm1, vm2, vm3]

      expect(vm1).to receive(:current_load_metrics)
      expect(vm2).to receive(:current_load_metrics)
      expect(vm3).to_not receive(:current_load_metrics)

      subject.perform
    end
  end

  context 'metrics db' do
    it 'saves metrics for each vm  with zabbix id that is managed by atmo' do
      vm1 = create(:virtual_machine, ip: '10.100.0.1', monitoring_id: 1, managed_by_atmosphere: true)
      vm2 = create(:virtual_machine, ip: '10.100.0.2', monitoring_id: 2, managed_by_atmosphere: true)
      vm3 = create(:virtual_machine, ip: '10.100.0.3', managed_by_atmosphere: true)
      metrics_double_1 = double('metrics1')
      metrics_double_2 = double('metrics2')
      metrics_double_3 = double('metrics3')
      allow(vm1).to receive(:current_load_metrics).and_return metrics_double_1
      allow(vm2).to receive(:current_load_metrics).and_return metrics_double_2
      allow(vm3).to receive(:current_load_metrics).and_return metrics_double_3

      allow(VirtualMachine).to receive(:all).and_return [vm1, vm2, vm3]

      expect(vm1).to receive(:save_load_metrics).with(metrics_double_1)
      expect(vm2).to receive(:save_load_metrics).with(metrics_double_2)
      expect(vm3).to_not receive(:save_load_metrics)

      subject.perform
    end
  end
end