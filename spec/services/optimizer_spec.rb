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

    context 'development mode' do

      let(:dev_appliance_set) { create(:dev_appliance_set) }
      let(:config_inst) { create(:appliance_configuration_instance) }
      it 'does not reuse available vm' do
        tmpl_of_shareable_at
        appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
        appl2 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
        vms = VirtualMachine.all
        expect(vms.size).to eql 2
        vm_1 = vms.first
        vm_2 = vms.last
        expect(vm_1.appliances.size).to eql 1
        expect(vm_2.appliances.size).to eql 1
        expect(vm_1.appliances).to eq [appl1]
        expect(vm_2.appliances).to eq [appl2]
      end

      it 'does not reuse available vm if it is in dev mode' do
          tmpl_of_shareable_at
          appl1 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          vms = VirtualMachine.all
          expect(vms.size).to eql 2
          vm_1 = vms.first
          vm_2 = vms.last
          expect(vm_1.appliances.size).to eql 1
          expect(vm_2.appliances.size).to eql 1
          expect(vm_1.appliances).to eq [appl1]
          expect(vm_2.appliances).to eq [appl2]
      end

      context 'sets vm name' do

        before do
          VirtualMachine.stub(:create)
        end

        it 'to appliance name if it is not blank' do
          appliance = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, name: 'name full appliance')
          vm_params = {name: appliance.name, source_template: tmpl_of_shareable_at, appliance_ids: [appliance.id], state: :build, virtual_machine_flavor: tmpl_of_shareable_at.compute_site.virtual_machine_flavors.first}
          expect(VirtualMachine).to have_received(:create).with(vm_params)
        end

        it 'to appliance type name if appliance name is blank' do
          appliance = create(:appliance, name: nil, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          vm_params = {name: appliance.appliance_type.name, source_template: tmpl_of_shareable_at, appliance_ids: [appliance.id], state: :build, virtual_machine_flavor: tmpl_of_shareable_at.compute_site.virtual_machine_flavors.first}
          expect(VirtualMachine).to have_received(:create).with(vm_params)
        end

      end

    end

    context 'shareable appliance type' do

      context 'vm cannot be reused' do

        it 'instantiates a new vm if there are no vms at all' do
          appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
          vms = VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 1
          expect(vm.appliances).to include appl
        end

        it 'sets appliance state to satisfied if vm was instantiated' do
          appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
          appl.reload
          expect(appl.state).to eql 'satisfied'
        end

        it 'does not reuse avaiable vm if appliances use config with equal payload and different ids' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance, payload: config_inst.payload))
          vms = VirtualMachine.all
          expect(vms.size).to eql 2
          vm_1 = vms.first
          vm_2 = vms.last
          expect(vm_1.appliances.size).to eql 1
          expect(vm_2.appliances.size).to eql 1
          expect(vm_1.appliances).to eq [appl1]
          expect(vm_2.appliances).to eq [appl2]
        end

        context 'max appl number equal one' do
          let(:config_inst) { create(:appliance_configuration_instance) }

          before do
            Air.config.optimizer.stub(:max_appl_no).and_return 1
          end

          it 'instantiates a new vm if already running vm cannot accept more load' do
            appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
            appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)

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
          appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          vms = VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 2
          expect(vm.appliances).to include(appl1, appl2)
        end

        it 'sets appliance state to satisfied if vm was reused' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          appl2.reload
          expect(appl2.state).to eql 'satisfied'
        end
      end
    end

    context 'not shareable appliance type' do
      let!(:not_shareable_appl_type) { create(:not_shareable_appliance_type) }
      let!(:tmpl_of_not_shareable_at) { create(:virtual_machine_template, appliance_type: not_shareable_appl_type)}

      it 'instantiates a new vm although vm with given conf is already running' do
        tmpl_of_not_shareable_at
        config_inst = create(:appliance_configuration_instance)
        appl1 = create(:appliance, appliance_set: wf, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst)
        appl2 = create(:appliance, appliance_set: wf2, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst)
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
    let(:at) { create(:appliance_type) }
    it 'sets appliance to unsatisfied state' do
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance))
      appl.reload
      expect(appl.state).to eql 'unsatisfied'
    end

    it 'sets state explanation' do
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance))
      appl.reload
      expect(appl.state_explanation).to eql "No matching template was found for appliance #{appl.name}"
    end

    it 'only saving tmpl exists' do
      saving_tmpl = create(:virtual_machine_template, appliance_type: at, state: :saving)
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance))
      appl.reload
      expect(appl.state).to eql 'unsatisfied'
    end

  end

  context 'flavor' do

    let(:amazon) { create(:amazon_with_flavors) }
    it 'includes flavor in params of created vm' do
      VirtualMachine.stub(:create)
      appl = create(:appliance, name: nil, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
      selected_flavor = subject.send(:select_tmpl_and_flavor, [tmpl_of_shareable_at]).last
      expect(VirtualMachine).to have_received(:create).with({name: shareable_appl_type.name, source_template: tmpl_of_shareable_at, appliance_ids: [appl.id], state: :build, virtual_machine_flavor: selected_flavor})
    end

    context 'is selected optimaly' do

      context 'appliance type preferences not specified' do

        it 'selects instance with at least 1.5GB RAM for public compute site' do
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, compute_site: amazon, appliance_type: appl_type)
          selected_tmpl, flavor = subject.send(:select_tmpl_and_flavor, [tmpl])
          expect(flavor.memory).to be >= 1536
        end

        it 'selects instance with 512MB RAM for private compute site' do
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, compute_site: openstack, appliance_type: appl_type)
          selected_tmpl, flavor = subject.send(:select_tmpl_and_flavor, [tmpl])
          expect(flavor.memory).to be >= 512
        end

      end

      context 'appliance type preferences specified' do

        let(:appl_type) { create(:appliance_type, preference_memory: 1024, preference_cpu: 2) }
        let(:tmpl_at_amazon) { create(:virtual_machine_template, compute_site: amazon, appliance_type: appl_type) }
        let(:tmpl_at_openstack) { create(:virtual_machine_template, compute_site: openstack, appliance_type: appl_type) }

        it 'selects cheapest flavour that satisfies requirements' do
          selected_tmpl, flavor = subject.send(:select_tmpl_and_flavor, [tmpl_at_amazon, tmpl_at_openstack])
          expect(flavor.memory).to be >= 1024
          expect(flavor.cpu).to be >= 2
          all_discarded_flavors = amazon.virtual_machine_flavors + openstack.virtual_machine_flavors - [flavor]
          all_discarded_flavors.each {|f|
            if(f.memory >= appl_type.preference_memory and f.cpu >= appl_type.preference_cpu)
              expect(f.hourly_cost >= flavor.hourly_cost).to be true
            end
          }
        end

        it 'selects flavor with more ram if prices are equal' do
          biggest_os_flavor = openstack.virtual_machine_flavors.max_by {|f| f.memory}
          optimal_flavor = create(:virtual_machine_flavor, memory: biggest_os_flavor.memory + 256, cpu: biggest_os_flavor.cpu, hdd: biggest_os_flavor.hdd, hourly_cost: biggest_os_flavor.hourly_cost, compute_site: amazon)
          amazon.reload
          appl_type.preference_memory = biggest_os_flavor.memory
          appl_type.save
          tmpl, flavor = subject.send(:select_tmpl_and_flavor, [tmpl_at_amazon, tmpl_at_openstack])
          expect(flavor).to eq optimal_flavor
          expect(tmpl).to eq tmpl_at_amazon
        end

        context 'preferences exceeds resources of avaiable flavors' do

          before do
            appl_type.preference_cpu = 64
            appl_type.save
          end

          it 'returns nil flavor' do
            tmpl, flavor = subject.send(:select_tmpl_and_flavor, [tmpl_at_amazon, tmpl_at_openstack])
            expect(flavor).to be_nil
          end

          it 'sets state explanation' do
            [tmpl_at_amazon, tmpl_at_openstack]
            appl = create(:appliance, appliance_set: wf, appliance_type: appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), name: 'my service')
            expect(appl.state_explanation).to eq "No matching flavor was found for appliance #{appl.name}"
          end

          it 'sets appliance as unsatisfied' do
            appl = create(:appliance, appliance_set: wf, appliance_type: appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
            expect(appl.state).to eq 'unsatisfied'
          end

        end

      end

    end
  end
end