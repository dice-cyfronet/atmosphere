require 'spec_helper'

describe Optimizer do

  before do
    Fog.mock!
  end

  let!(:wf) { create(:workflow_appliance_set) }
  let!(:wf2) { create(:workflow_appliance_set) }
  let!(:shareable_appl_type) { create(:shareable_appliance_type) }
  let!(:openstack) { create(:openstack_with_flavors) }
  let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type, compute_site: openstack)}

  subject { Optimizer.instance }

  it 'is not nil' do
     expect(subject).not_to be_nil
  end

  context 'new appliance created' do

    context 'shareable appliance type' do

      context 'vm cannot be reused' do

        it 'instantiates a new vm if there are no vms at all' do
          appl = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
          vms = VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 1
          expect(vm.appliances).to include appl
        end

        it 'sets appliance state to satisfied if vm was instantiated' do
          appl = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
          appl.reload
          expect(appl.state).to eql 'satisfied'
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

        it 'sets appliance state to satisfied if vm was reused' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2 = Appliance.create(appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2.reload
          expect(appl2.state).to eql 'satisfied'
        end

        it 'triggers proxy regeneration if vm was reused' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl1.reload
          expect(ProxyConfWorker).to receive(:regeneration_required).with(appl1.virtual_machines.first.compute_site)
          appl2 = Appliance.create(appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
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

  context 'virtual machine is applianceless' do
    let!(:external_vm) { create(:virtual_machine) }
    let!(:vm) { create(:virtual_machine, managed_by_atmosphere: true) }

    before do
      servers_double = double
      vm.compute_site.cloud_client.stub(:servers).and_return(servers_double)
      allow(servers_double).to receive(:destroy)
    end

    it 'terminates unused manageable vm' do
      subject.run(destroyed_appliance: true)

      expect(VirtualMachine.count).to eq 1
      expect(VirtualMachine.first).to eq external_vm
    end
  end

  context 'no template is available' do

    it 'sets appliance to unsatisfied state' do
      appl = Appliance.create(appliance_set: wf, appliance_type: create(:appliance_type), appliance_configuration_instance: create(:appliance_configuration_instance))
      appl.reload
      expect(appl.state).to eql 'unsatisfied'
    end

    it 'only saving tmpl exists'

  end

  context 'flavor' do

    it 'includes flavor in params of created vm' do
      VirtualMachine.stub(:create)
      appl = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
      expect(VirtualMachine).to have_received(:create).with({name: shareable_appl_type.name, source_template: tmpl_of_shareable_at, appliance_ids: [appl.id], state: :build, virtual_machine_flavor: subject.send(:select_flavor, tmpl_of_shareable_at)})
    end

    context 'is selected optimaly' do

      context 'appliance type preferences not specified' do

        it 'selects instance with at least 1.5GB RAM for public compute site' do
          amazon = build(:amazon_with_flavors)
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, compute_site: amazon, appliance_type: appl_type)
          flavor = subject.send(:select_flavor, tmpl)
          expect(flavor.memory).to be >= 1536
        end

        it 'selects instance with 512MB RAM for private compute site' do
          openstack = build(:openstack_with_flavors)
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, compute_site: openstack, appliance_type: appl_type)
          flavor = subject.send(:select_flavor, tmpl)
          expect(flavor.memory).to be >= 512
        end

      end

      context 'appliance type preferences specified' do

        it 'selects cheapest flavour that satisfies requirements' do
          
        end

      end

    end
  end
end