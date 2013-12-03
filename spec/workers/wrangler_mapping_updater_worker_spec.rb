require 'spec_helper'

describe WranglerMappingUpdaterWorker do

  before do
    Optimizer.instance.stub(:run)
    Fog.mock!
  end

  let(:proto) { 'tcp' }
  let(:priv_port) { 8080 }
  let(:public_port_1) { 12345 }
  let(:public_port_2) { 6789 }
  let(:priv_ip) { '10.1.1.1' }
  let(:pub_ip) { '149.156.9.48' }

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end
  end

  context 'does not invoke remote Wrangler service' do

    let(:pmt) { create(:port_mapping_template) }
    let(:vm_ipless) { create(:virtual_machine) }
    let(:vm) { create(:virtual_machine, ip: priv_ip) }

    before do
      dnat_client_mock = double('dnat client mock')
      Wrangler::Client.stub(:dnat_client).and_return dnat_client_mock
      expect(dnat_client_mock).to_not receive(:delete)
      expect(dnat_client_mock).to_not receive(:post)
      vm.stub(:update_mapping)
      vm.stub(:add_dnat)
      vm.stub(:delete_dnat)
      vm.stub(:regenerate_dnat)
    end

    context 'vm or pmt does not exists in DB' do
      it 'does nothing if vm does not exist' do
        non_existing_vm_id = VirtualMachine.last ? VirtualMachine.last.id + 1 : 1
        expect { subject.perform(non_existing_vm_id, pmt.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does nothing if pmt does not exist' do
        non_existing_pmt_id = PortMappingTemplate.last ? PortMappingTemplate.last.id + 1 : 1
        expect { subject.perform(vm.id, non_existing_pmt_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

    it 'does nothing if pmt is not associated with any of mappings of the vm' do
      subject.perform(vm.id, pmt.id)
    end

  end

  context 'using remote Wrangler client' do

    let(:appliance) { create(:appliance) }
    let!(:vm) { create(:virtual_machine, ip: priv_ip, appliances: [appliance]) }
    let(:pmt) { create(:port_mapping_template, target_port: priv_port, appliance_type: vm.appliance_type, application_protocol: :none) }
    let!(:pm) { create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt, source_port: public_port_1) }

    before do
      vm.stub(:update_mapping)
      vm.stub(:add_dnat)
      vm.stub(:delete_dnat)
      vm.stub(:regenerate_dnat)
    end

    context 'remote Wrangler service invocation succeeds' do
      stubs = nil
      before do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}])) {[200, {}, "[{\"privIp\":\"#{priv_ip}\",\"pubPort\":#{public_port_2},\"proto\":\"#{proto}\",\"privPort\":#{priv_port},\"pubIp\":\"#{pub_ip}\"}]"]}
          stub.delete("/dnat/#{priv_ip}/#{priv_port.to_s}") {[204, {}, nil]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
      end
      
      it 'removes existing mapping associated with pmt from Wrangler and adds a new one' do
        subject.perform(vm.id, pmt.id)
        stubs.verify_stubbed_calls
      end

      it 'updates port mapping in DB' do
        subject.perform(vm.id, pmt.id)
        pm.reload
        expect(pm.source_port).to eq public_port_2
      end

    end
  

    context 'error handling' do
      let(:logger_mock) { double('logger') }
      stubs = nil
      before do
        Rails.stub(:logger).and_return logger_mock
      end

      it 'logs error for 500 response status when deleting mapping' do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.delete("/dnat/#{priv_ip}/#{priv_port.to_s}") {[500, {}, "Wrangler internal error"]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
        expect(logger_mock).to receive(:error).with("Wrangler returned 500 Wrangler internal error when trying to remove redirection for IP #{priv_ip}:#{priv_port}")
        subject.perform(vm.id, pmt.id)
      end

      it 'logs error for 500 response status when creating mapping' do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}])) {[500, {}, "Wrangler internal error"]}
          stub.delete("/dnat/#{priv_ip}/#{priv_port.to_s}") {[204, {}, nil]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
        expect(logger_mock).to receive(:error).with("Wrangler returned 500 Wrangler internal error when trying to add redirections for VM #{vm.uuid} with IP #{priv_ip}. Requested redirections: [{:proto=>\"tcp\", :port=>#{priv_port}}]")
        subject.perform(vm.id, pmt.id)
      end

      it 'does not modify mapping in DB if remote Wrangler service returned 500' do
        allow(logger_mock).to receive(:error)
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{priv_ip}", JSON.generate([{proto: proto, port: priv_port}])) {[500, {}, "Wrangler internal error"]}
          stub.delete("/dnat/#{priv_ip}/#{priv_port.to_s}") {[500, {}, 'Wrangler internal error']}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
        subject.perform(vm.id, pmt.id)
        expect(pm.created_at).to eq pm.updated_at
      end
    end

  end

end