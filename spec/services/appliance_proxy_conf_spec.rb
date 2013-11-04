require 'spec_helper'

describe ApplianceProxyConf do

  before do
    Fog.mock!

    # We want to test proxy conf generation not VM and PMT callbacks
    VirtualMachine.any_instance.stub(:generate_proxy_conf).and_return(true)
    PortMappingTemplate.any_instance.stub(:generate_proxy_conf).and_return(true)
  end

  describe '#generate' do
    let(:cs) { create(:compute_site) }
    let(:appl_type) { create(:appliance_type)}

    context 'when production appliance started on cloud site' do
      # cs
      # |-> appl_type
      #   |-> appl
      #     |-> vm1
      #     |-> vm2
      #     |-> vm_without_ip
      let(:vm1) { create(:virtual_machine, compute_site: cs, ip: "10.100.8.10")}
      let(:vm2) { create(:virtual_machine, compute_site: cs, ip: "10.100.8.11")}
      let(:vm_without_ip) { create(:virtual_machine, compute_site: cs, ip: nil) }
      let(:appl) { create(:appliance, appliance_type: appl_type, virtual_machines: [ vm1, vm2, vm_without_ip])}

      subject { ApplianceProxyConf.new(appl) }

      context 'with http port mapping template' do
        let!(:http_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :http)}

        it 'generates http redirection' do
          expect(subject.generate).to eq [
            redirection(appl, http_pmt, [vm1, vm2], :http)
          ]
        end

        it 'creates missing port mapping' do
          expect {
            subject.generate
          }.to change { HttpMapping.count }.by(1)
        end

        it 'sets port mapping url' do
          subject.generate
          expect(http_pmt.http_mappings.first.url).to eq path(appl, http_pmt)
        end

        context 'with added property' do
          let!(:pm_prop1) { create(:pmt_property, key: 'k1', value: 'v1', port_mapping_template: http_pmt) }
          let!(:pm_prop2) { create(:pmt_property, key: 'k2', value: 'v2', port_mapping_template: http_pmt) }

          it 'generates additional properties key' do
            redirection = redirection(appl, http_pmt, [vm1, vm2], :http)
            redirection[:properties] = [ 'k1 v1', 'k2 v2']
            expect(subject.generate).to eq [ redirection ]
          end
        end
      end

      context 'with https port mapping template' do
        let!(:https_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :https)}

        it 'generates https redirection' do
          expect(subject.generate).to eq [
            redirection(appl, https_pmt, [vm1, vm2], :https)
          ]
        end

        it 'creates missing port mapping' do
          expect {
            subject.generate
          }.to change { HttpMapping.count }.by(1)
        end
      end

      context 'with http_https port mapping template' do
        let!(:http_https_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :http_https)}

        it 'generates https redirection' do
          expect(subject.generate).to eq [
            redirection(appl, http_https_pmt, [vm1, vm2], :http),
            redirection(appl, http_https_pmt, [vm1, vm2], :https)
          ]
        end

        it 'creates missing port mapping' do
          expect {
            subject.generate
          }.to change { HttpMapping.count }.by(2)
        end

        context 'when one port mapping exists' do
          let!(:port_mapping) { create(:http_mapping, appliance: appl, port_mapping_template: http_https_pmt) }

          it 'creates only missing port mapping' do
            expect {
              subject.generate
            }.to change { HttpMapping.count }.by(1)
          end

          it 'updates port mapping url if needed' do
            subject.generate
            port_mapping.reload
            expect(port_mapping.url).to eq path(appl, http_https_pmt)
          end
        end
      end
    end

    context 'when development appliance started on cloud site' do
      # app_type
      #   |-> http_pmt
      let!(:http_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :http, service_name: 'old_name', target_port: 80)}

      # appliance_set
      # |-> appl (with pmt copied from appl_type)
      #      |-> vm
      let(:appliance_set) { create(:appliance_set, appliance_set_type: :development) }
      let(:vm) { create(:virtual_machine, compute_site: cs, ip: "10.100.8.10")}
      let(:appl) { create(:appliance, appliance_type: appl_type, appliance_set: appliance_set, virtual_machines: [ vm ])}
      let(:dev_pmt) { appl.dev_mode_property_set.port_mapping_templates.first }

      subject { ApplianceProxyConf.new(appl) }

      it 'creates http redirection for pmt copied from appliance type' do
        expect(subject.generate).to eq [
          redirection(appl, http_pmt, [vm], :http),
        ]
      end

      context 'when modified copied pmt' do
        before do
          dev_pmt.target_port = 8080
          dev_pmt.service_name = 'new_name'
          dev_pmt.application_protocol = :https
          dev_pmt.save
        end

        it 'creates http redirection using development pmt' do
          expect(subject.generate).to eq [
            redirection(appl, dev_pmt, [vm], :https),
          ]
        end
      end

      context 'when new pmt added in dev mode' do
        let!(:new_pmt) do
          appl.dev_mode_property_set.port_mapping_templates.create(
            target_port: 443,
            service_name: 'somtething_secured',
            application_protocol: :https
          )
        end

        it 'creates https redirection for added pmt' do
          expect(subject.generate).to eq [
            redirection(appl, dev_pmt, [vm], :http),
            redirection(appl, new_pmt, [vm], :https),
          ]
        end

        it 'creates new https pm' do
          expect {
            subject.generate
            }.to change { HttpMapping.count }.by(2)
        end
      end

      context 'when removed pmt' do
        before do
          dev_pmt.destroy
          # reload cached appliance object, to discover dev_pmt deletion
          appl.reload
        end

        it 'creates empty redirections list' do
          expect(subject.generate).to eq []
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
end