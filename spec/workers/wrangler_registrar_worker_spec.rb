require 'spec_helper'

describe WranglerRegistrarWorker do

  before do
    Optimizer.instance.stub(:run)
  end

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end
  end

  let(:priv_ip)          { '10.1.2.3' }
  let(:pub_ip)           { '149.156.9.5' }
  let(:proto)            { 'tcp' }
  let(:priv_port)        { 8888 }
  let(:priv_port_2)      { 8889 }
  let(:priv_port_3)      { 8890 }
  let(:pub_port)         { 11921 }
  let(:pub_port_2)       { 11922 }
  let(:invalid_port_no)  { 100000000 }

  context 'appliance in dev mode has port mapping templates defined in dev mode properties' do
    let(:pmt) { create(:dev_port_mapping_template) }
    let(:appl) { create(:appl_dev_mode, dev_mode_property_set: pmt.dev_mode_property_set) }

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}])) {[200, {}, "[{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port},\"proto\":\"#{proto}\",\"privPort\":#{priv_port},\"pubIp\":\"#{pub_ip}\"}]"]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'calls remote wrangler service when updating dnat for a vm in dev mode' do
      appl = create(:appl_dev_mode)
      pmt = create(:dev_port_mapping_template, dev_mode_property_set: appl.dev_mode_property_set, target_port: priv_port, application_protocol: 'none')
      vm = create(:virtual_machine, appliances: [appl])
      vm.reload
      vm.update_attribute(:ip, priv_ip)
      subject.perform(vm.id)
      stubs.verify_stubbed_calls
    end

  end

  context 'vm already has one port mapping and a new port mapping template is added' do
    before do
      Optimizer.instance.stub(:run)
    end
    let(:priv_ip) { '10.1.1.1' }
    #let(:pub_ip) { '149.156.9.5' }
    let(:proto) { 'tcp' }
    let(:priv_port) { 8080 }
    let(:priv_port_2) { 9999 }
    let(:appliance) { create(:appliance)}
    let(:vm) { create(:virtual_machine, ip: priv_ip, appliances: [appliance]) }

    it 'adds second port mapping' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port_2}])) {[200, {}, "[{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port},\"proto\":\"#{proto}\",\"privPort\":#{priv_port_2},\"pubIp\":\"#{pub_ip}\"}]"]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
      vm.stub(:update_dnat)
      pmt_1 = create(:port_mapping_template, target_port: priv_port, appliance_type: vm.appliance_type, application_protocol: :none)
      pm = create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt_1)
      pmt_2 = create(:port_mapping_template, target_port: priv_port_2, appliance_type: vm.appliance_type, application_protocol: :none)
      expect {
        subject.perform(vm.id)
      }.to change {PortMapping.count}.by 1
      expect(PortMapping.count).to eq 2
      expect(PortMappingTemplate.count).to eq 2
    end

  end

  context 'appliance type has three port mapping templates among which one is http and must not be added to wrangler' do

    let!(:appl_type) { create(:filled_appliance_type) }
    let!(:port_mapping_tmpl) { create(:port_mapping_template, target_port: priv_port, application_protocol: 'none', appliance_type: appl_type) }
    let!(:port_mapping_tmpl_2) { create(:port_mapping_template, target_port: priv_port_2, application_protocol: 'none', appliance_type: appl_type) }
    let!(:port_mapping_tmpl_3) { create(:port_mapping_template, target_port: priv_port_3, application_protocol: 'http', appliance_type: appl_type) }
    let(:appl) { create(:appliance, appliance_type: appl_type) }

    context 'using wrangler client' do

      stubs = nil
      before do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}, {proto: proto, port: priv_port_2}])) {[200, {}, "[{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port},\"proto\":\"#{proto}\",\"privPort\":#{priv_port},\"pubIp\":\"#{pub_ip}\"},{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port_2},\"proto\":\"#{proto}\",\"privPort\":#{priv_port_2},\"pubIp\":\"#{pub_ip}\"}]"]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
      end

      it 'calls remote wrangler service' do
        vm = create(:virtual_machine, ip: priv_ip, appliances: [appl])
        subject.perform(vm.id)
        stubs.verify_stubbed_calls
      end

      it 'adds port mapping to vm when application protocol is none' do
        vm = create(:virtual_machine, ip: priv_ip, appliances: [appl])
        subject.perform(vm.id)
        vm.reload
        expect(vm.port_mappings.size).to eql 2
      end

    end

    context 'error handling' do
      let(:logger_mock) { double('logger') }
      stubs = nil
      before do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}, {proto: proto, port: priv_port_2}])) {[500, {}, "Wrangler internal error"]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
        Rails.stub(:logger).and_return logger_mock
      end

      it 'checks HTTP status in wrangler response' do
        vm = create(:virtual_machine, ip: priv_ip, appliances: [appl])
        expect(logger_mock).to receive(:error) { "Wrangler returned 500 Wrangler internal error when trying to add redirections for VM #{vm.uuid} with IP #{priv_ip}. Requested redirections: [{:proto=>\"tcp\", :port=>#{priv_port}}, {:proto=>\"#{proto}\", :port=>#{priv_port_2}}]" }
        subject.perform(vm.id)
        stubs.verify_stubbed_calls
      end

      it 'logs error and does nothing for invalid port number' do
        create(:port_mapping_template, target_port: invalid_port_no, application_protocol: 'none', appliance_type: appl_type)
        vm = create(:virtual_machine, ip: priv_ip, appliances: [appl])
        expect(logger_mock).to receive(:error) { "Error when trying to add redirections for VM #{vm.uuid} with IP #{priv_ip}. Requested redirection for forbidden port #{invalid_port_no}" }
        subject.perform(vm.id)
        # below is an ugly way of verifying that wrangler was not invoked :-)
        expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
      end

    end

  end



  context 'appliance type does not have any port mapping templates' do
    let!(:appl_type) { create(:filled_appliance_type) }
    let(:appl) { create(:appliance, appliance_type: appl_type) }

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}, {proto: proto, port: priv_port_2}])) {[200, {}, "[{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port},\"proto\":\"#{proto}\",\"privPort\":#{priv_port},\"pubIp\":\"#{pub_ip}\"},{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port_2},\"proto\":\"#{proto}\",\"privPort\":#{priv_port_2},\"pubIp\":\"#{pub_ip}\"}]"]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'does nothing if appliance type has no port mapping templates' do
      vm = create(:virtual_machine, ip: priv_ip, appliances: [appl])
      subject.perform(vm.id)
      vm.reload
      expect(vm.port_mappings).to be_blank
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end

  end
  context 'vm does not have ip' do

    let!(:appl_type) { create(:filled_appliance_type) }
    let!(:port_mapping_tmpl) { create(:port_mapping_template, target_port: priv_port, application_protocol: 'none', appliance_type: appl_type) }
    let!(:tmpl) { create(:source_template, appliance_type: appl_type) }

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}, {proto: proto, port: priv_port_2}])) {[200, {}, "[{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port},\"proto\":\"#{proto}\",\"privPort\":#{priv_port},\"pubIp\":\"#{pub_ip}\"},{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{pub_port_2},\"proto\":\"#{proto}\",\"privPort\":#{priv_port_2},\"pubIp\":\"#{pub_ip}\"}]"]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'does nothing if vm has no ip' do
      vm = create(:virtual_machine, source_template: tmpl)
      subject.perform(vm.id)
      vm.reload
      expect(vm.port_mappings).to be_blank
      # below is an ugly way of verifying that wrangler was not invoked :-)
      expect { stubs.verify_stubbed_calls }.to raise_error(RuntimeError)
    end
  end
end