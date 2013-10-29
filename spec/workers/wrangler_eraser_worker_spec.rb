require 'spec_helper'

describe WranglerEraserWorker do

  context 'building appropriate path for Wragler request' do
  
    it 'builds appropriate path for ip only' do
      eraser = WranglerEraserWorker.new
      ip = '10.10.8.8'
      path = eraser.build_path_for_params(ip, nil, nil)
      expect(path).to eql "/dnat/#{ip}"
    end

    it 'builds appropriate path ip and port' do
      eraser = WranglerEraserWorker.new
      ip = '10.10.8.8'
      port = 8888
      path = eraser.build_path_for_params(ip, port, nil)
      expect(path).to eql "/dnat/#{ip}/#{port.to_s}"
    end

    it 'builds appropriate path for ip, port and protcol' do
      eraser = WranglerEraserWorker.new
      ip = '10.10.8.8'
      port = 8888
      protocol = 'tcp'
      path = eraser.build_path_for_params(ip, port, protocol)
      expect(path).to eql "/dnat/#{ip}/#{port.to_s}/#{protocol}"
    end

  end

  context 'error handling' do
  end

end