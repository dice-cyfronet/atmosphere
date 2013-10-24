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
      subject.perform(PRIV_IP, PROTO, PRIV_PORT)
      stubs.verify_stubbed_calls
    end
  end

  it 'raises error for invliad protcol' do
    pending
  end

  it 'raises error for forbidden port number' do
    pending
  end

end