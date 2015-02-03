require 'rails_helper'

describe Atmosphere::ApplianceVmsManager do

  before(:suite) do
   Fog.mock!
   
 end

  let(:server_id) { 'SERVER_ID' }
  let(:cep) { double('cep') }
  let(:appl) do
    double('appliance', :state= => true, virtual_machines: double(:<< => true))
  end
  let(:tmpl) { create(:virtual_machine_template) }
  let(:updater) { double('updater', update: true) }
  let(:updater_class) { double('updater class', new: updater) }
  let(:tags_mng) { double('tags manager', create_tags_for_vm: nil) }
  let(:tags_manager_class) { double('tags manager class', new: tags_mng) }

  subject do
    Atmosphere::ApplianceVmsManager.new(
      appl,
      updater_class,
      Atmosphere::Cloud::VmCreator,
      tags_manager_class
    )
  end


  before(:example) do
    allow(Atmosphere).to receive(:cep_client).and_return(cep)
    allow(subject).to receive(:start_vm_on_cloud).and_return(server_id)
    allow(Atmosphere::BillingService).to receive(:can_afford_flavor?).
      and_return(true)
    allow_any_instance_of(Atmosphere::VirtualMachine).to receive(:valid?).
      and_return(true)
  end

  context 'optimization policy uses CEP' do
    let(:simple_ev) { {name: 'SIMPLE EVENT', event_properties: {} }}
    let(:complex_ev) { 'EPL QUERY' }
    let(:ev_defs) { {simple_event: simple_ev, complex_event: complex_ev} }
    let(:opt_strategy) { double('CEPFull strategy', event_definitions: ev_defs) }

    it 'registers vm in CEP engine' do
      allow(appl).to receive(:optimization_strategy).and_return(opt_strategy)
      expect(cep).to receive(:add_event_type).with(simple_ev)
      expect(cep).to receive(:subscribe).with(complex_ev)
      subject.spawn_vm!(tmpl, nil, 'CEPFULL')
    end

  end

  context 'optimization policy does not use CEP' do
    it 'does not register vm in CEP engine' do
      allow(appl).to receive(:optimization_strategy).
        and_return(Atmosphere::OptimizationStrategy::Default.new(nil))
      # we expect that cep double is not invoked
      subject.spawn_vm!(tmpl, nil, 'CEPLESS')
    end
  end

end