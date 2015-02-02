require 'rails_helper'

describe Atmosphere::VmLoadMonitoringWorker do

  before {
    Fog.mock!
  }

  let!(:vm1) { create(:virtual_machine, ip: '10.100.0.1', monitoring_id: 1, managed_by_atmosphere: true) }
  let!(:vm2) { create(:virtual_machine, ip: '10.100.0.2', monitoring_id: 2, managed_by_atmosphere: true) }
  let!(:vm3) { create(:virtual_machine, ip: '10.100.0.3', managed_by_atmosphere: true) }
      let!(:vm4) { create(:virtual_machine, ip: '10.100.0.4', monitoring_id: 3) }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end

    it { should be_retryable false }
    it { should be_processed_in :monitoring }
  end

  context 'Zabbix' do
    it 'queries Zabbix for each vm with zabbix id that are managed by atmosphere' do  
      allow(Atmosphere::VirtualMachine)
        .to receive(:monitorable).and_return [vm1, vm2]

      expect(vm1).to receive(:current_load_metrics)
      expect(vm2).to receive(:current_load_metrics)
      expect(vm3).to_not receive(:current_load_metrics)
      expect(vm4).to_not receive(:current_load_metrics)

      subject.perform
    end
  end

  context 'metrics db' do
    it 'saves metrics for each vm  with zabbix id that is managed by atmo' do
      metrics_double_1 = double('metrics1')
      metrics_double_2 = double('metrics2')
      metrics_double_3 = double('metrics3')
      allow(vm1).to receive(:current_load_metrics).and_return metrics_double_1
      allow(vm2).to receive(:current_load_metrics).and_return metrics_double_2

      allow(Atmosphere::VirtualMachine)
        .to receive(:monitorable).and_return [vm1, vm2]

      expect(vm1).to receive(:save_load_metrics).with(metrics_double_1)
      expect(vm2).to receive(:save_load_metrics).with(metrics_double_2)
      expect(vm3).to_not receive(:save_load_metrics)

      subject.perform
    end
  end
end