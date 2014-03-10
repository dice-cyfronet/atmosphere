require 'spec_helper'

describe VirtualMachine do

  let(:metrics_double) { double('metrics double') }

  before {
    Fog.mock! 
    Zabbix.stub(:register_host).and_return 1
    Zabbix.stub(:unregister_host)
    Zabbix.stub(:host_metrics).and_return metrics_double
  }

  context 'current load metrics' do
    it 'queries Zabbix' do
      expect(Zabbix).to receive(:host_metrics)
      expect(metrics_double).to receive(:collect_last)
      vm = create(:virtual_machine, ip: '10.100.0.1', zabbix_host_id: 1)
      vm.current_load_metrics
    end
  end

end