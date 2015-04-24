require 'rails_helper'

describe Atmosphere::Cloud::SatisfyAppliance do
  include VmtOnCsHelpers

  before do
    # Temporary solution allowing to not execute optimization process.
    # It is needed untill optimizer is not removed from the appliance callback.
    allow(Atmosphere::Optimizer).
      to receive(:instance).
      and_return(instance_double(Atmosphere::Optimizer, run: true))
  end

  let!(:wf) { create(:workflow_appliance_set) }
  let!(:wf2) { create(:workflow_appliance_set) }
  let!(:shareable_appl_type) { create(:shareable_appliance_type) }
  let!(:fund) { create(:fund) }
  let!(:openstack) { create(:openstack_with_flavors, funds: [fund]) }
  let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type, compute_site: openstack)}

  context 'new appliance created' do
    context 'development mode' do
      let(:dev_appliance_set) { create(:dev_appliance_set) }
      let(:config_inst) { create(:appliance_configuration_instance) }
      it 'does not reuse available vm' do
        tmpl_of_shareable_at
        appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)
        appl2 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)

        described_class.new(appl1).execute
        described_class.new(appl2).execute

        vms = Atmosphere::VirtualMachine.all
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
        appl1 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)
        appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)

        described_class.new(appl1).execute
        described_class.new(appl2).execute

        vms = Atmosphere::VirtualMachine.all
        expect(vms.size).to eql 2
        vm_1 = vms.first
        vm_2 = vms.last
        expect(vm_1.appliances.size).to eql 1
        expect(vm_2.appliances.size).to eql 1
        expect(vm_1.appliances).to eq [appl1]
        expect(vm_2.appliances).to eq [appl2]
      end

      context 'sets vm name' do
        let(:appl_vm_manager) do
          double('appliance_vms_manager',
            :can_reuse_vm? => false,
            save: true
          )
        end

        before do
          allow(Atmosphere::ApplianceVmsManager).to receive(:new)
            .and_return(appl_vm_manager)
        end

        it 'to appliance name if it is not blank' do
          name = 'name full appliance'
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, n|
            expect(n).to eq name
          end

          appl = create(:appliance, appliance_set: dev_appliance_set,
                        appliance_type: shareable_appl_type, name: name,
                        fund: fund, compute_sites: Atmosphere::ComputeSite.all)

          described_class.new(appl).execute
        end

        it 'to appliance type name if appliance name is blank' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, n|
            expect(n).to eq shareable_appl_type.name
          end

          appl = create(:appliance, name: nil, appliance_set: dev_appliance_set,
                        appliance_type: shareable_appl_type, fund: fund,
                        compute_sites: Atmosphere::ComputeSite.all)

          described_class.new(appl).execute
        end
      end
    end

    shared_examples 'not_enough_funds' do
      it 'set appliance state to unsatisfied' do
        expect(appl2.state).to eq 'unsatisfied'
      end

      it 'describe user why appliance state cannot be satisfied' do
        expect(appl2.state_explanation).to eq 'Not enough funds'
      end

      it 'has no VM assigned' do
        expect(appl2.virtual_machines.count).to eq 0
      end
    end

    context 'shareable appliance type' do

      context 'vm cannot be reused' do

        it 'instantiates a new vm if there are no vms at all' do
          appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, compute_sites: Atmosphere::ComputeSite.all)

          described_class.new(appl).execute

          vms = Atmosphere::VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 1
          expect(vm.appliances).to include appl
        end

        it 'sets appliance state to satisfied if vm was instantiated' do
          appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, compute_sites: Atmosphere::ComputeSite.all)

          described_class.new(appl).execute

          appl.reload
          expect(appl.state).to eql 'satisfied'
        end

        it 'does not reuse avaiable vm if appliances use config with equal payload and different ids' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)
          appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance, payload: config_inst.payload), fund: fund, compute_sites: Atmosphere::ComputeSite.all)

          described_class.new(appl1).execute
          described_class.new(appl2).execute

          vms = Atmosphere::VirtualMachine.all
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
            allow(Atmosphere.optimizer).to receive(:max_appl_no).and_return 1
          end

          it 'instantiates a new vm if already running vm cannot accept more load' do
            appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)
            appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all)

            described_class.new(appl1).execute
            described_class.new(appl2).execute

            vms = Atmosphere::VirtualMachine.all
            expect(vms.size).to eql 2
            appl1.reload
            appl2.reload
            expect(appl1.virtual_machines.size).to eql 1
            expect(appl2.virtual_machines.size).to eql 1
            vm1 = appl1.virtual_machines.first
            vm2 = appl2.virtual_machines.first
            expect(vm1 == vm2).to be_falsy
          end
        end
      end

      context 'vm can be reused' do
        let(:config_inst) { create(:appliance_configuration_instance) }
        let!(:appl1) { create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all) }
        let(:appl2) { create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all) }

        before do
          described_class.new(appl1).execute
        end

        context 'and user has emough funds to start appliance' do
          before do
            appl1.reload
            allow(Atmosphere::BillingService).to receive(:can_afford_vm?).with(anything, appl1.virtual_machines.first).and_return(true)
            allow(Atmosphere::BillingService).to receive(:bill_appliance)
            appl2.reload

            described_class.new(appl1).execute
            described_class.new(appl2).execute
          end

          it 'reuses available vm' do
            vms = Atmosphere::VirtualMachine.all
            expect(vms.size).to eql 1
            vm = vms.first
            expect(vm.appliances.size).to eql 2
            expect(vm.appliances).to include(appl1, appl2)
          end

          it 'sets appliance state to satisfied if vm was reused' do
            expect(appl2.state).to eql 'satisfied'
          end

          it 'triggers billing' do
            expect(Atmosphere::BillingService).to have_received(:bill_appliance)
          end
        end

        context 'and user does not have emough funds to start appliance' do
          before do
            appl1.reload
            allow(Atmosphere::BillingService).to receive(:can_afford_vm?).with(anything, appl1.virtual_machines.first).and_return(false)

            described_class.new(appl2).execute
          end

          it_behaves_like 'not_enough_funds'
        end
      end
    end

    context 'not shareable appliance type' do
      let(:not_shareable_appl_type) { create(:not_shareable_appliance_type) }
      let(:cs) { create(:openstack_with_flavors, funds: [fund]) }
      let!(:tmpl_of_not_shareable_at) { create(:virtual_machine_template, appliance_type: not_shareable_appl_type, compute_site: cs)}
      let(:config_inst) { create(:appliance_configuration_instance) }
      let!(:appl1) { create(:appliance, appliance_set: wf, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all) }
      let(:appl2) { create(:appliance, appliance_set: wf2, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, compute_sites: Atmosphere::ComputeSite.all) }

      context 'and user has emough funds to start appliance' do
        before do
          allow(Atmosphere::BillingService).to receive(:can_afford_vm?).with(anything, appl1.virtual_machines.first).and_return(true)

          described_class.new(appl1).execute
          described_class.new(appl2).execute
        end

        it 'instantiates a new vm although vm with given conf is already running' do
          vms = Atmosphere::VirtualMachine.all
          expect(vms.size).to eql 2
          expect(appl1.virtual_machines.size).to eql 1
          expect(appl2.virtual_machines.size).to eql 1
          vm1 = appl1.virtual_machines.first
          vm2 = appl2.virtual_machines.first
          expect(vm1 == vm2).to be_falsy
        end
      end

      context 'and user does not have emough funds to start appliance' do
        before do
          allow(Atmosphere::BillingService).
            to receive(:can_afford_flavor?).
            and_return(false)

          described_class.new(appl2).execute

          appl2.reload
        end

        it_behaves_like 'not_enough_funds'
      end
    end

    context 'when one of compute site with VMTs is turned off' do
      it 'failed when all VMTs are on inactive compute site' do
        _, inactive_vmt = vmt_on_site(cs_active: false)
        at = create(:appliance_type, virtual_machine_templates: [inactive_vmt])
        appl = create(:appliance, appliance_set: wf, appliance_type: at)

        described_class.new(appl).execute

        expect(appl.state).to eql 'unsatisfied'
        expect(appl.state_explanation).to start_with 'No matching template'
      end

      it 'chooses VMT from active compute site' do
        inactive_cs, inactive_vmt = vmt_on_site(cs_active: false)
        active_cs, active_vmt = vmt_on_site(cs_active: true)
        flavor = create(:virtual_machine_flavor,
          compute_site: active_cs, id_at_site: '123')
        allow(Atmosphere::BillingService).to receive(:can_afford_flavor?)
          .with(anything, flavor).and_return(true)
        at = create(:appliance_type,
          virtual_machine_templates: [inactive_vmt, active_vmt])
        appl = create(:appliance,
          appliance_set: wf, appliance_type: at,
          compute_sites: [inactive_cs, active_cs])

        described_class.new(appl).execute
        selected_vmt = appl.virtual_machines.first.source_template

        expect(appl.state).to eql 'satisfied'
        expect(selected_vmt).to eql active_vmt
      end
    end

    context 'when one of the flavor is turned off' do
      it 'failed when there is not active flavor' do
        cs, vmt = vmt_on_site(cs_active: true)
        create(:flavor, active: false, compute_site: cs)
        at = create(:appliance_type, virtual_machine_templates: [vmt])
        appl = create(:appliance, appliance_set: wf,
          appliance_type: at, compute_sites: [cs])

        described_class.new(appl).execute

        expect(appl.state).to eql 'unsatisfied'
        expect(appl.state_explanation).to start_with 'No matching flavor'
      end

      it 'chooses VMT with active flavor' do
        cs, vmt = vmt_on_site(cs_active: true)
        create(:flavor, active: false, compute_site: cs)
        active_flavor = create(:flavor,
            active: true,
            compute_site: cs,
            id_at_site: '123'
          )
        at = create(:appliance_type, virtual_machine_templates: [vmt])
        allow(Atmosphere::BillingService).to receive(:can_afford_flavor?)
          .with(anything, active_flavor).and_return(true)
        appl = create(:appliance, appliance_set: wf,
          appliance_type: at, compute_sites: [cs])

        described_class.new(appl).execute

        expect(appl.state).to eql 'satisfied'
        expect(appl.virtual_machines
          .first.virtual_machine_flavor).to eq active_flavor
      end
    end
  end

  context 'no template is available' do
    let(:at) { create(:appliance_type) }
    it 'sets appliance to unsatisfied state' do
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, compute_sites: Atmosphere::ComputeSite.all)

      described_class.new(appl).execute
      appl.reload

      expect(appl.state).to eql 'unsatisfied'
    end

    it 'sets state explanation' do
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, compute_sites: Atmosphere::ComputeSite.all)

      described_class.new(appl).execute
      appl.reload

      expect(appl.state_explanation).to eql "No matching template was found for appliance #{appl.name}"
    end

    it 'only saving tmpl exists' do
      saving_tmpl = create(:virtual_machine_template, appliance_type: at, state: :saving)
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, compute_sites: Atmosphere::ComputeSite.all)

      described_class.new(appl).execute
      appl.reload

      expect(appl.state).to eql 'unsatisfied'
    end
  end
end
