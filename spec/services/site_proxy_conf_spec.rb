require 'spec_helper'

describe SiteProxyConf do

  before { Fog.mock! }

  let(:cs) { create(:compute_site) }
  subject { SiteProxyConf.new(cs) }

  describe "#generate" do
    let(:appl_type) { create(:appliance_type)}

    context 'when no appliances' do
      it 'returns no redirections' do
        expect(subject.generate).to eq []
      end
    end

    context 'when appliance started on cloud site' do
      # cs
      # |-> appl_type
      #   |-> appl1
      #     |-> vm1
      let!(:appl1) { create(:appliance, appliance_type: appl_type)}
      let!(:vm1) { create(:virtual_machine, appliances: [ appl1 ], compute_site: cs, ip: "10.100.8.10")}
      let(:appl1_proxy_conf) { double }

      before {
        expect(ApplianceProxyConf).to receive(:new).with(appl1).and_return(appl1_proxy_conf)
        expect(appl1_proxy_conf).to receive(:generate).and_return(['appl1', 'proxy conf'])
      }

      it 'genrates appliance proxy conf' do
        expect(subject.generate).to eq [
          'appl1', 'proxy conf'
        ]
      end

      context 'when second appliance started' do
        # cs
        # |-> appl_type
        #   |-> appl
        #     |-> vm1
        #   |-> appl2
        #     |-> vm2
        let!(:appl2) { create(:appliance, appliance_type: appl_type)}
        let!(:vm2) { create(:virtual_machine, appliances: [ appl2 ], compute_site: cs, ip: "10.100.8.11")}
        let(:appl2_proxy_conf) { double }

        before {
          expect(ApplianceProxyConf).to receive(:new).with(appl2).and_return(appl2_proxy_conf)
          expect(appl2_proxy_conf).to receive(:generate).and_return(['appl2'])
        }

        it 'generates proxy conf for all site appliances' do
          expect(subject.generate).to eq [
            'appl1', 'proxy conf', 'appl2'
          ]
        end
      end
    end
  end

  describe '#properties' do
    context 'when properties added to compute site' do
      let!(:pm_prop1) { create(:port_mapping_property, key: 'k1', value: 'v1', compute_site: cs) }
      let!(:pm_prop2) { create(:port_mapping_property, key: 'k2', value: 'v2', compute_site: cs) }

      it 'generates proxy conf properties' do
        expect(subject.properties).to eq [
          'k1 v1',
          'k2 v2'
        ]
      end
    end
  end
end