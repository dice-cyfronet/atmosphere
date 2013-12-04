require 'spec_helper'

describe WranglerEraserWorker do

  let(:priv_ip)           { '10.10.8.8' }
  let(:priv_port)         { 8888 }
  let(:priv_port_2)       { 7777 }
  let(:protocol)          { 'tcp' }
  let(:http_int_err_code) { 500 }
  before do
    wrg = double('wrangler')
    DnatWrangler.stub(:instance).and_return wrg
  end

  context 'building appropriate path for Wragler request' do

    it 'builds appropriate path for ip only' do
      path = subject.build_path_for_params(priv_ip, nil, nil)
      expect(path).to eql "/dnat/#{priv_ip}"
    end

    it 'builds appropriate path ip and port' do
      path = subject.build_path_for_params(priv_ip, priv_port, nil)
      expect(path).to eql "/dnat/#{priv_ip}/#{priv_port.to_s}"
    end

    it 'builds appropriate path for ip, port and protcol' do
      path = subject.build_path_for_params(priv_ip, priv_port, protocol)
      expect(path).to eql "/dnat/#{priv_ip}/#{priv_port.to_s}/#{protocol}"
    end

  end

  context 'error handling' do

    let(:logger_mock) { double('logger') }


    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/dnat/#{priv_ip}") {[http_int_err_code, {}, nil]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
      Rails.stub(:logger).and_return logger_mock
    end

    it 'logs error if wrangler returns non 204 status' do
      expect(logger_mock).to receive(:error).with("Wrangler returned #{http_int_err_code.to_s} when trying to remove redirections for IP #{priv_ip}.")
      vm = create(:virtual_machine, ip: priv_ip)
      subject.perform(vm_id: vm.id)
    end

  end

  context 'using wrangler client' do

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/dnat/#{priv_ip}") {[204, {}, nil]}
        stub.delete("/dnat/#{priv_ip}/#{priv_port.to_s}/#{protocol}") {[204, {}, nil]}
        stub.delete("/dnat/#{priv_ip}/#{priv_port_2.to_s}/#{protocol}") {[204, {}, nil]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'calls remote wrangler service' do
      vm = create(:virtual_machine, ip: priv_ip)
      pmt = create(:port_mapping_template, target_port: priv_port)
      pmt2 = create(:port_mapping_template, target_port: priv_port_2)
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
      vm = create(:virtual_machine, ip: priv_ip)
      subject.perform(vm_id: vm.id)
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end

    context 'removes port mappings from DB' do
      let(:vm) { create(:virtual_machine, ip: priv_ip) }
      let(:pmt) { create(:port_mapping_template, target_port: priv_port) }
      let(:pmt2) { create(:port_mapping_template, target_port: priv_port_2) }
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