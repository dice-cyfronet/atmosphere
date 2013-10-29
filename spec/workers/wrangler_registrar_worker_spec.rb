require 'spec_helper'

describe WranglerRegistrarWorker do

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end
  end

  PRIV_IP = '10.1.2.3'
  PUB_IP = '149.156.9.5'
  PROTO = 'tcp'
  PRIV_PORT = 8888
  PRIV_PORT_2 = 8889
  PRIV_PORT_3 = 8890
  PUB_PORT = 11921
  PUB_PORT_2 = 11922
  INVALID_PORT_NO = 100000000

  context 'appliance type has three port mapping templates among which one is http and must not be added to wrangler' do

    let!(:appl_type) { create(:filled_appliance_type) }
    let!(:port_mapping_tmpl) { create(:port_mapping_template, target_port: PRIV_PORT, application_protocol: 'none', appliance_type: appl_type) }
    let!(:port_mapping_tmpl_2) { create(:port_mapping_template, target_port: PRIV_PORT_2, application_protocol: 'none', appliance_type: appl_type) }
    let!(:port_mapping_tmpl_3) { create(:port_mapping_template, target_port: PRIV_PORT_3, application_protocol: 'http', appliance_type: appl_type) }
    let!(:tmpl) { create(:source_template, appliance_type: appl_type) }

    context 'using wrangler client' do
    
      stubs = nil
      before do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{PRIV_IP}", JSON.generate([{proto: PROTO, port: PRIV_PORT}, {proto: PROTO, port: PRIV_PORT_2}])) {[200, {}, "[{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT},\"pubIp\":\"#{PUB_IP}\"},{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT_2},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT_2},\"pubIp\":\"#{PUB_IP}\"}]"]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
      end

      it 'calls remote wrangler service' do
        vm = create(:virtual_machine, source_template: tmpl, ip: PRIV_IP)
        subject.perform(vm)
        stubs.verify_stubbed_calls
      end

      it 'adds port mapping to vm when application protocol is none' do
        vm = create(:virtual_machine, source_template: tmpl, ip: PRIV_IP)
        subject.perform(vm)
        vm.reload
        expect(vm.port_mappings.size).to eql 2
      end

    end

    context 'error handling' do
      let(:logger_mock) { double('logger') }
      stubs = nil
      before do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{PRIV_IP}", JSON.generate([{proto: PROTO, port: PRIV_PORT}, {proto: PROTO, port: PRIV_PORT_2}])) {[500, {}, "Wrangler internal error"]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
        Rails.stub(:logger).and_return logger_mock
      end
      
      it 'checks HTTP status in wrangler response' do
        vm = create(:virtual_machine, source_template: tmpl, ip: PRIV_IP)
        expect(logger_mock).to receive(:error) { "Wrangler returned 500 Wrangler internal error when trying to add redirections for VM #{vm.uuid} with IP #{PRIV_IP}. Requested redirections: [{:proto=>\"tcp\", :port=>#{PRIV_PORT}}, {:proto=>\"#{PROTO}\", :port=>#{PRIV_PORT_2}}]" }
        subject.perform(vm)
        stubs.verify_stubbed_calls
      end

      it 'logs error and does nothing for invalid port number' do
        create(:port_mapping_template, target_port: INVALID_PORT_NO, application_protocol: 'none', appliance_type: appl_type)
        vm = create(:virtual_machine, source_template: tmpl, ip: PRIV_IP)
        expect(logger_mock).to receive(:error) { "Error when trying to add redirections for VM #{vm.uuid} with IP #{PRIV_IP}. Requested redirection for forbidden port #{INVALID_PORT_NO}" }
        subject.perform(vm)
        # below is an ugly way of verifying that wrangler was not invoked :-)
        expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
      end

    end

  end

  

  context 'appliance type does not have any port mapping templates' do
    let!(:appl_type) { create(:filled_appliance_type) }
    let!(:tmpl) { create(:source_template, appliance_type: appl_type) }

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/dnat/#{PRIV_IP}", JSON.generate([{proto: PROTO, port: PRIV_PORT}, {proto: PROTO, port: PRIV_PORT_2}])) {[200, {}, "[{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT},\"pubIp\":\"#{PUB_IP}\"},{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT_2},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT_2},\"pubIp\":\"#{PUB_IP}\"}]"]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'does nothing if appliance type has no port mapping templates' do
      vm = create(:virtual_machine, source_template: tmpl, ip: PRIV_IP)
      subject.perform(vm)
      vm.reload
      expect(vm.port_mappings).to be_blank
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end

  end
  context 'vm does not have ip' do

    let!(:appl_type) { create(:filled_appliance_type) }
    let!(:port_mapping_tmpl) { create(:port_mapping_template, target_port: PRIV_PORT, application_protocol: 'none', appliance_type: appl_type) }
    let!(:tmpl) { create(:source_template, appliance_type: appl_type) }

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/dnat/#{PRIV_IP}", JSON.generate([{proto: PROTO, port: PRIV_PORT}, {proto: PROTO, port: PRIV_PORT_2}])) {[200, {}, "[{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT},\"pubIp\":\"#{PUB_IP}\"},{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT_2},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT_2},\"pubIp\":\"#{PUB_IP}\"}]"]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'does nothing if vm has no ip' do
      vm = create(:virtual_machine, source_template: tmpl)
      subject.perform(vm)
      vm.reload
      expect(vm.port_mappings).to be_blank
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end
  end
end