require 'spec_helper'

describe VmLoadMonitoringWorker do
  include FogHelpers

  before {
    Fog.mock!
    Zabbix.stub(:register_host).and_return 'zabbix_host_id'
    Zabbix.stub(:unregister_host)
  }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end

    it { should be_retryable false }
    it { should be_processed_in :monitoring }
  end

  context 'Zabbix' do
    it 'queries Zabbix for each vm with zabbix id' do
      vm1 = create(:virtual_machine, ip: '10.100.0.1', zabbix_host_id: 1)
      vm2 = create(:virtual_machine, ip: '10.100.0.2', zabbix_host_id: 2)
      vm3 = create(:virtual_machine, ip: '10.100.0.3')
      VirtualMachine.stub(:all).and_return [vm1, vm2, vm3]

      expect(vm1).to receive(:current_load_metrics)
      expect(vm2).to receive(:current_load_metrics)
      expect(vm3).to_not receive(:current_load_metrics)

      subject.perform
    end
  end

  context 'metrics db' do
    it 'saves metrics for each vm  with zabbix id' do
      vm1 = create(:virtual_machine, ip: '10.100.0.1', zabbix_host_id: 1)
      vm2 = create(:virtual_machine, ip: '10.100.0.2', zabbix_host_id: 2)
      vm3 = create(:virtual_machine, ip: '10.100.0.3')
      metrics_double_1 = double('metrics1')
      metrics_double_2 = double('metrics2')
      metrics_double_3 = double('metrics3')
      vm1.stub(:current_load_metrics).and_return metrics_double_1
      vm2.stub(:current_load_metrics).and_return metrics_double_2
      vm3.stub(:current_load_metrics).and_return metrics_double_3

      VirtualMachine.stub(:all).and_return [vm1, vm2, vm3]

      expect(vm1).to receive(:save_load_metrics).with(metrics_double_1)
      expect(vm2).to receive(:save_load_metrics).with(metrics_double_2)
      expect(vm3).to_not receive(:save_load_metrics)

      subject.perform
    end
  end
end