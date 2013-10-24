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
  PUB_PORT = 11921

  context 'appliance type has one port mapping template' do

    let!(:appl_type) { create(:filled_appliance_type) }
    let!(:port_mapping_tmpl) { create(:port_mapping_template, target_port: PRIV_PORT, appliance_type: appl_type) }
    let!(:tmpl) { create(:source_template, appliance_type: appl_type) }

    context 'using wrangler client' do
    
      stubs = nil
      before do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/dnat/#{PRIV_IP}", JSON.generate([{proto: PROTO, port: PRIV_PORT}])) {[200, {}, "[{\"privIp\":\"#{PRIV_IP}\",\"pubPort\":#{PUB_PORT},\"proto\":\"#{PROTO}\",\"privPort\":#{PRIV_PORT},\"pubIp\":\"#{PUB_IP}\"}]"]}
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

      it 'adds port mapping to vm' do
        vm = create(:virtual_machine, source_template: tmpl, ip: PRIV_IP)
        subject.perform(vm)
        vm.reload
        expect(vm.port_mappings.size).to eql 1
      end
    
    end

  end

  it 'raises error for invliad protcol' do
    pending
  end

  it 'raises error for forbidden port number' do
    pending
  end

  it 'does nothing if appliance type has no port mapping templates' do
    pending
  end

  it 'raises error if vm has no ip' do
    pending
  end

  it 'checks HTTP status in wrangler response' do
    pending
  end
  
end