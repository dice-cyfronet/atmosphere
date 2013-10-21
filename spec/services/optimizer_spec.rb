require 'spec_helper'

describe Optimizer do

  before do
    Fog.mock!
  end

  subject { Optimizer.instance }

  it 'is not nil' do
     expect(subject).not_to be_nil
  end

  context 'new appliance created' do

    let!(:wf) { create(:workflow_appliance_set) }
    let!(:wf2) { create(:workflow_appliance_set) }

    context 'shareable appliance type' do
      let!(:shareable_appl_type) { create(:shareable_appliance_type) }
      let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type)}

      context 'vm cannot be reused' do

        it 'instantiates a new vm if there are no vms at all' do
          tmpl_of_shareable_at
          appl = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
          vms = VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 1
          expect(vm.appliances).to include appl
        end

        context 'max appl number equal one' do
          let(:config_inst) { create(:appliance_configuration_instance) }
          
          before do
            Air.config.optimizer.stub(:max_appl_no).and_return 1
          end

          it 'instantiates a new vm if already running vm cannot accept more load' do
            appl1 = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
            appl2 = Appliance.create(appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)

            vms = VirtualMachine.all
            expect(vms.size).to eql 2
            appl1.reload
            appl2.reload
            expect(appl1.virtual_machines.size).to eql 1
            expect(appl2.virtual_machines.size).to eql 1
            vm1 = appl1.virtual_machines.first
            vm2 = appl2.virtual_machines.first
            expect(vm1 == vm2).to be_false
          end
        end

      end

      context 'vm can be reused' do

        it 'reuses available vm' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2 = Appliance.create(appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          # expect(ApplianceSet.all.size).to eql 2 # WTF?
          vms = VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 2
          expect(vm.appliances).to include(appl1, appl2)
        end

      end
    end

    context 'not shareable appliance type' do
      let!(:not_shareable_appl_type) { create(:not_shareable_appliance_type) }
      let!(:tmpl_of_not_shareable_at) { create(:virtual_machine_template, appliance_type: not_shareable_appl_type)}
      it 'instantiates a new vm although vm with given conf is already running' do
        tmpl_of_not_shareable_at
        config_inst = create(:appliance_configuration_instance)
        appl1 = Appliance.create(appliance_set: wf, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst)
        appl2 = Appliance.create(appliance_set: wf2, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst)
        vms = VirtualMachine.all
        expect(vms.size).to eql 2
        appl1.reload
        appl2.reload
        expect(appl1.virtual_machines.size).to eql 1
        expect(appl2.virtual_machines.size).to eql 1
        vm1 = appl1.virtual_machines.first
        vm2 = appl2.virtual_machines.first
        expect(vm1 == vm2).to be_false
      end

    end
  end
end