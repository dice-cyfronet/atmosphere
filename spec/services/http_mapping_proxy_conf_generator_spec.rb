require 'spec_helper'

describe HttpMappingProxyConfGenerator do

  before { Fog.mock! }

  describe "#new" do
    it "creates a new proxy conf generator" do
      expect(subject).to be_an_instance_of HttpMappingProxyConfGenerator
    end
  end


  describe "#run" do

    context 'when no appliances' do
      let(:cs) { create(:compute_site) }

      it 'returns no redirections' do
        expect(subject.run(cs)).to eq []
      end
    end

    context 'when production appliance started on cloud site' do
      # cs
      # |-> appl_type
      #   |-> appl
      #     |-> vm1
      #     |-> vm2
      let(:cs) { create(:compute_site) }
      let(:appl_type) { create(:appliance_type)}
      let(:appl) { create(:appliance, appliance_type: appl_type)}
      let!(:vm1) { create(:virtual_machine, appliances: [ appl ], compute_site: cs, ip: "10.100.8.10")}
      let!(:vm2) { create(:virtual_machine, appliances: [ appl ], compute_site: cs, ip: "10.100.8.11")}

      context 'with http port mapping template' do
        let!(:http_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :http)}

        it 'generates http redirection' do
          expect(subject.run(cs)).to eq [
            redirection(appl, http_pmt, [vm1, vm2], :http)
          ]
        end

        it 'creates missing port mapping' do
          expect {
            subject.run(cs)
          }.to change { HttpMapping.count }.by(1)
        end

        it 'sets port mapping url' do
          subject.run(cs)
          expect(http_pmt.http_mappings.first.url).to eq path(appl, http_pmt)
        end
      end

      context 'with https port mapping template' do
        let!(:https_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :https)}

        it 'generates https redirection' do
          expect(subject.run(cs)).to eq [
            redirection(appl, https_pmt, [vm1, vm2], :https)
          ]
        end

        it 'creates missing port mapping' do
          expect {
            subject.run(cs)
          }.to change { HttpMapping.count }.by(1)
        end
      end

      context 'with http_https port mapping template' do
        let!(:http_https_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :http_https)}

        it 'generates https redirection' do
          expect(subject.run(cs)).to eq [
            redirection(appl, http_https_pmt, [vm1, vm2], :http),
            redirection(appl, http_https_pmt, [vm1, vm2], :https)
          ]
        end

        it 'creates missing port mapping' do
          expect {
            subject.run(cs)
          }.to change { HttpMapping.count }.by(2)
        end

        context 'when one port mapping exists' do
          let!(:port_mapping) { create(:http_mapping, appliance: appl, port_mapping_template: http_https_pmt) }

          it 'creates only missing port mapping' do
            expect {
              subject.run(cs)
            }.to change { HttpMapping.count }.by(1)
          end

          it 'updates port mapping url if needed' do
            subject.run(cs)
            port_mapping.reload
            expect(port_mapping.url).to eq path(appl, http_https_pmt)
          end
        end
      end
    end
  end

  def redirection(appl, pmt, vms, type)
    {
      path: path(appl, pmt),
      workers: vms.collect { |vm| "#{vm.ip}:#{pmt.target_port}" },
      type: type
    }
  end

  def path(appl, pmt)
    "#{appl.appliance_set.id}/#{appl.appliance_configuration_instance.id}/#{pmt.service_name}"
  end
end