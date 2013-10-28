require 'spec_helper'

describe HttpMappingProxyConfGenerator do

  before { Fog.mock! }

  describe "#new" do
    it "creates a new proxy conf generator" do
      expect(subject).to be_an_instance_of HttpMappingProxyConfGenerator
    end
  end


  describe "#run" do
    let(:cs) { create(:compute_site) }

    context 'when no appliances' do
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
      let(:appl_type) { create(:appliance_type)}
      let(:appl) { create(:appliance, appliance_type: appl_type)}
      let!(:vm1) { create(:virtual_machine, appliances: [ appl ], compute_site: cs, ip: "10.100.8.10")}
      let!(:vm2) { create(:virtual_machine, appliances: [ appl ], compute_site: cs, ip: "10.100.8.11")}

      context 'with http port mapping template' do
        let!(:http_pmt) { create(:port_mapping_template, appliance_type: appl_type, application_protocol: :http)}

        context 'when second appliance started' do
          let(:appl2) { create(:appliance, appliance_type: appl_type)}
          before {
            vm1.appliances << appl2
          }

          it 'generates http redirections for both appliances' do
            expect(subject.run(cs)).to eq [
              redirection(appl, http_pmt, [vm1, vm2], :http),
              redirection(appl2, http_pmt, [vm1], :http)
            ]
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