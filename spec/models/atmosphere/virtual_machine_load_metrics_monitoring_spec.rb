require 'rails_helper'

describe Atmosphere::VirtualMachine do

  let(:metrics_double) { double('metrics double') }
  let(:mon_cli_double) { double('monitoring client') }

  before {
    Fog.mock!
    allow(Atmosphere).to receive(:monitoring_client).and_return mon_cli_double
  }

  context 'current load metrics' do
    it 'queries monitoring' do
      expect(mon_cli_double).to receive(:host_metrics).and_return metrics_double
      expect(metrics_double).to receive(:collect_last)
      vm = create(:virtual_machine, ip: '10.100.0.1', monitoring_id: 1)
      vm.current_load_metrics
    end
  end
end
