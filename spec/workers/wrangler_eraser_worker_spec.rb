require 'spec_helper'

describe WranglerEraserWorker do

  PRIV_IP = '10.10.8.8'
  PRIV_PORT = 8888
  PROTOCOL = 'tcp'

  context 'building appropriate path for Wragler request' do
  
    it 'builds appropriate path for ip only' do
      eraser = WranglerEraserWorker.new
      path = eraser.build_path_for_params(PRIV_IP, nil, nil)
      expect(path).to eql "/dnat/#{PRIV_IP}"
    end

    it 'builds appropriate path ip and port' do
      eraser = WranglerEraserWorker.new  
      path = eraser.build_path_for_params(PRIV_IP, PRIV_PORT, nil)
      expect(path).to eql "/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}"
    end

    it 'builds appropriate path for ip, port and protcol' do
      eraser = WranglerEraserWorker.new
      path = eraser.build_path_for_params(PRIV_IP, PRIV_PORT, PROTOCOL)
      expect(path).to eql "/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}/#{PROTOCOL}"
    end

  end

  context 'error handling' do
    
  end

  context 'using wrangler client' do

    stubs = nil
    before do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/dnat/#{PRIV_IP}") {[204, {}, nil]}
        stub.delete("/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}") {[204, {}, nil]}
        stub.delete("/dnat/#{PRIV_IP}/#{PRIV_PORT.to_s}/#{PROTOCOL}") {[204, {}, nil]}
      end
      stubbed_dnat_client = Faraday.new do |builder|
        builder.adapter :test, stubs
      end
      Wrangler::Client.stub(:dnat_client).and_return stubbed_dnat_client
    end

    it 'calls remote wrangler service' do
      subject.perform(PRIV_IP)
      subject.perform(PRIV_IP, PRIV_PORT)
      subject.perform(PRIV_IP, PRIV_PORT, PROTOCOL)
      stubs.verify_stubbed_calls
    end
  end

end