require 'spec_helper'

describe WranglerEraserWorker do

  PRIV_IP = '10.10.8.8'
  PRIV_PORT = 8888
  PRIV_PORT_2 = 7777
  PROTOCOL = 'tcp'
  HTTP_INT_ERR_CODE = 500

  context 'building appropriate path for Wragler request' do
  
    it 'builds appropriate path for ip only' do
      path = subject.build_path_for_params(PRIV_IP, nil, nil)
      expect(path).to eql "/dnat/#{PRIV_IP}"
    end

    it 'builds appropriate path ip and port' do
      path = subject.build_path_for_params(PRIV_IP, PRIV_PORT, nil)
      expect(path).to eql "/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}"
    end

    it 'builds appropriate path for ip, port and protcol' do
      path = subject.build_path_for_params(PRIV_IP, PRIV_PORT, PROTOCOL)
      expect(path).to eql "/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}/#{PROTOCOL}"
    end

  end

  context 'error handling' do

    let(:logger_mock) { double('logger') }


    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/dnat/#{PRIV_IP}") {[HTTP_INT_ERR_CODE, {}, nil]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
      Rails.stub(:logger).and_return logger_mock
    end

    it 'logs error if wrangler returns non 204 status' do
      expect(logger_mock).to receive(:error) { "Wrangler returned #{HTTP_INT_ERR_CODE.to_s} when trying to remove redirections for IP #{PRIV_IP}." }
      vm = create(:virtual_machine, ip: PRIV_IP)
      subject.perform(vm_id: vm.id)
    end
    
  end

  context 'using wrangler client' do

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/dnat/#{PRIV_IP}") {[204, {}, nil]}
        stub.delete("/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}/#{PROTOCOL}") {[204, {}, nil]}
        stub.delete("/dnat/#{PRIV_IP}/#{PRIV_PORT_2.to_s}/#{PROTOCOL}") {[204, {}, nil]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'calls remote wrangler service' do
      vm = create(:virtual_machine, ip: PRIV_IP)
      pmt = create(:port_mapping_template, target_port: PRIV_PORT)
      pmt2 = create(:port_mapping_template, target_port: PRIV_PORT_2)
      pm = create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt)
      subject.perform(vm_id: vm.id)
      pm = create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt)
      pm2 = create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt2)
      subject.perform(port_mapping_ids: [pm.id, pm2.id])
      stubs.verify_stubbed_calls
    end

    it 'does nothing if vm does not have an IP' do
      vm = create(:virtual_machine)
      subject.perform(vm_id: vm.id)
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end

    it 'does nothing if vm does not have port mappings' do
      vm = create(:virtual_machine, ip: PRIV_IP)
      subject.perform(vm_id: vm.id)
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end

    context 'removes port mappings from DB' do
      let(:vm) { create(:virtual_machine, ip: PRIV_IP) }
      let(:pmt) { create(:port_mapping_template, target_port: PRIV_PORT) }
      let(:pmt2) { create(:port_mapping_template, target_port: PRIV_PORT_2) }
      let!(:pm) { create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt) }
      let!(:pm2) { create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt2) }
      
      it 'destroys one port mapping' do
        subject.perform(port_mapping_ids: [pm.id])
        # awkward way of checking that pm was destroyed by another process
        expect { pm.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys two port mappings' do
        subject.perform(port_mapping_ids: [pm.id, pm2.id])
        # awkward way of checking that pm was destroyed by another process
        expect { pm.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { pm2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys all mappings for a vm' do
        expect(vm.port_mappings.size).to eql 2
        subject.perform(vm_id: vm.id)
        vm.reload
        expect(vm.port_mappings.size).to eql 0
      end

    end
  end

end