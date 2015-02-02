require 'rails_helper'

describe Atmosphere::DnatWrangler do

  let(:priv_ip)           { '10.10.8.8' }
  let(:priv_port)         { 8888 }
  let(:priv_port_2)       { 7777 }
  let(:protocol)          { 'tcp' }
  let(:http_int_err_code) { 500 }
  let(:vm) { create(:virtual_machine, ip: priv_ip) }
  let(:vm_ipless) { create(:virtual_machine) }
  let(:vm_mappingless) { create(:virtual_machine, ip: priv_ip) }
  let(:pmt) { create(:port_mapping_template, target_port: priv_port) }
  let(:pmt2) { create(:port_mapping_template, target_port: priv_port_2) }
  let!(:pm) { create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt) }
  let!(:pm2) { create(:port_mapping, virtual_machine: vm, port_mapping_template: pmt2) }

  context 'wrangler config is provided' do

    subject { Atmosphere::DnatWrangler.new('http://10.0.0.1:8080/dnat', 'wrangler_user', 'wrangler_passwd') }

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
          stub.delete("/dnat/#{priv_ip}/#{priv_port}/#{protocol}") {[http_int_err_code, {}, nil]}
        end
        stubbed_dnat_client = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        allow(subject).to receive(:dnat_client).and_return stubbed_dnat_client
        allow(Rails).to receive(:logger).and_return logger_mock
      end

      it 'logs error if wrangler returns non 204 status when deleting DNAT for vm' do
        expect(logger_mock).to receive(:error).with("Wrangler returned #{http_int_err_code.to_s} when trying to remove redirections for IP #{priv_ip}.")
        subject.remove(vm.ip)
      end

      it 'returns false if wrangler returns non 204 status when deleting DNAT for vm' do
        allow(logger_mock).to receive(:error).with("Wrangler returned #{http_int_err_code.to_s} when trying to remove redirections for IP #{priv_ip}.")
        expect(subject.remove(vm.ip)).to be_falsy
      end

      it 'logs error if wrangler returns non 204 status when deleting DNAT for mapping' do
        expect(logger_mock).to receive(:error).with("Wrangler returned #{http_int_err_code.to_s} when trying to remove redirections for IP #{priv_ip}, port #{priv_port}, protocol #{protocol}.")
        subject.remove_port_mapping(pm)
      end

      it 'returns false if wrangler returns non 204 status when deleting DNAT for mapping' do
        allow(logger_mock).to receive(:error).with("Wrangler returned #{http_int_err_code.to_s} when trying to remove redirections for IP #{priv_ip}, port #{priv_port}, protocol #{protocol}.")
        expect(subject.remove_port_mapping(pm)).to be_falsy
      end

    end

    context 'when removing DNAT' do

      context 'using wrangler client' do
        it 'removes existing redirection' do
          stub_dnat_with_response_status(200)

          expect(subject.remove(vm.ip)).to be_truthy
          expect(subject.remove_port_mapping(pm)).to be_truthy
          expect(subject.remove_port_mapping(pm2)).to be_truthy
        end

        it 'removes non existing redirection' do
          stub_dnat_with_response_status(204)

          expect(subject.remove(vm.ip)).to be_truthy
          expect(subject.remove_port_mapping(pm)).to be_truthy
          expect(subject.remove_port_mapping(pm2)).to be_truthy
        end

        def stub_dnat_with_response_status(status)
          stubs = Faraday::Adapter::Test::Stubs.new do |stub|
            stub.delete("/dnat/#{priv_ip}") { [status, {}, nil] }

            stub.delete("/dnat/#{priv_ip}/#{priv_port}/#{protocol}") do
              [status, {}, nil]
            end
            stub.delete("/dnat/#{priv_ip}/#{priv_port_2}/#{protocol}") do
              [status, {}, nil]
            end
          end
          stubbed_dnat_client = Faraday.new do |builder|
            builder.adapter :test, stubs
          end

          allow(subject).to receive(:dnat_client).
            and_return stubbed_dnat_client
        end
      end

      context 'does not call remote wrangler service' do

        stubs = nil
        before do
          stubs = Faraday::Adapter::Test::Stubs.new
          stubbed_dnat_client = Faraday.new do |builder|
            builder.adapter :test, stubs
          end
          allow(subject).to receive(:dnat_client).and_return stubbed_dnat_client
        end

        it 'if vm does not have an IP' do
          subject.remove(vm_ipless.ip)
        end

      end

    end

    context 'when adding DNAT' do
      context 'returns empty array' do
        it 'for a vm without ip' do
          expect(subject.add_dnat_for_vm(vm_ipless, [pmt])).to match_array []
        end

        it 'for empty port maping templates array' do
          expect(subject.add_dnat_for_vm(vm, [])).to match_array []
        end
      end

    end

  end

  context 'wrangler config is not provided' do

    subject { Atmosphere::DnatWrangler.new(nil, nil, nil) }

    context 'when adding DNAT' do
      context 'returns empty array' do
        it 'for a vm without ip' do
          expect(subject.add_dnat_for_vm(vm_ipless, [pmt])).to match_array []
        end

        it 'for empty port maping templates array' do
          expect(subject.add_dnat_for_vm(vm, [])).to match_array []
        end
      end

      it 'returns parameters for creating PortMapping objects with source ports equal to target ports in PortMappingTemplate' do
        params = subject.add_dnat_for_vm(vm, [pmt])
        expect(params).to eq [{port_mapping_template: pmt, virtual_machine: vm, public_ip: vm.ip, source_port: pmt.target_port}]
      end

    end

    context 'when deleting DNAT' do
      it 'returns true for ipless vm' do
        expect(subject.remove(vm_ipless.ip)).to be true
      end

      it 'returns true for a vm with an ip' do
        expect(subject.remove(vm.ip)).to be true
      end
    end

  end

end