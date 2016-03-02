require 'rails_helper'

describe Atmosphere::VmLoadMonitoringWorker do

  let(:monitoring_client) { double("Monitoring client") }
  let(:metrics_store) { double("Metric store") }

  before do
    Fog.mock!
    allow(Atmosphere).
      to receive(:monitoring_client).
      and_return(monitoring_client)

    allow(Atmosphere).
      to receive(:metrics_store).
      and_return(metrics_store)
  end

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end

    it { should be_retryable false }
    it { should be_processed_in :monitoring }
  end

  it 'queries monitoring for managed vm load' do
    create(:virtual_machine, ip: '10.100.0.1',
           monitoring_id: 1, managed_by_atmosphere: true)
    create(:virtual_machine, ip: '10.100.0.3', managed_by_atmosphere: true)
    create(:virtual_machine, ip: '10.100.0.4', monitoring_id: 3)

    expect(monitoring_client).to receive(:host_metrics).with(1)

    subject.perform
  end

  it 'saves metrics' do
    vm = create(:virtual_machine, ip: '10.100.0.1',
                 monitoring_id: 1, managed_by_atmosphere: true,
                 appliances: [create(:appliance)])
    metrics = double(collect_last: [{
      'Processor load (1 min average per core)' => 1,
      'Processor load (5 min average per core)' => 5,
      'Processor load (15 min average per core)' => 15,
      'Total memory' => 100.0,
      'Available memory' => 20.0
    }])
    allow(monitoring_client).
      to receive(:host_metrics).with(1).and_return(metrics)
    expect(metrics_store).
      to receive(:write_point).with('cpu_load_1', metric_point(vm, 1))
    expect(metrics_store).
      to receive(:write_point).with('cpu_load_5', metric_point(vm, 5))
    expect(metrics_store).
      to receive(:write_point).with('cpu_load_15', metric_point(vm, 15))
    expect(metrics_store).
      to receive(:write_point).with('memory_usage', metric_point(vm, 0.8))

    subject.perform
  end

  def metric_point(vm, value)
    appl = vm.appliances.first
    {
      appliance_set_id: appl.appliance_set_id,
      appliance_id: appl.id,
      virtual_machine_id: vm.uuid,
      value: value
    }
  end
end

