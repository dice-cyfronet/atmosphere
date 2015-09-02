require 'rails_helper'

describe Atmosphere::Cloud::SatisfyAppliance do
  include VmtOnTHelpers

  before do
    # Temporary solution allowing to not execute optimization process.
    # It is needed untill optimizer is not removed from the appliance callback.
    allow(Atmosphere::Optimizer.instance).to receive(:run)
  end

  let!(:fund) { create(:fund) }
  let!(:u) { create(:user, funds: [fund]) }
  let!(:wf) { create(:workflow_appliance_set, user: u) }
  let!(:wf2) { create(:workflow_appliance_set, user: u) }
  let!(:shareable_appl_type) { create(:shareable_appliance_type) }
  let!(:openstack) { create(:openstack_with_flavors, funds: [fund]) }
  let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type, tenants: [openstack])}

  context '#assign fund' do
    let!(:t) { create(:openstack_with_flavors, active: true, funds: [fund]) }
    let!(:vmt) { create(:virtual_machine_template, tenants: [t]) }
    let!(:appliance_type) do
      create(
        :appliance_type,
        preference_cpu: 0,
        preference_disk: 0,
        preference_memory: 0,
        virtual_machine_templates: [vmt]
      )
    end
    let!(:appliance_set) { create(:appliance_set, user: u) }
    let!(:appliance) do
      create(:appliance,
             appliance_set: appliance_set,
             appliance_type: appliance_type,
             tenants: [],
             fund: nil)
    end

    it 'gets default fund from its user if no fund is set' do
      Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute
      expect(appliance.fund).to eq u.default_fund
    end

    it 'prefers default fund if it supports relevant tenant' do
      appliance.reload
      default_t = create(
        :openstack_with_flavors,
        active: true,
        funds: [appliance_set.user.default_fund]
      )
      funded_t_fund = create(:fund)
      funded_t = create(
        :openstack_with_flavors,
        active: true,
        funds: [funded_t_fund]
      )
      appliance_set.user.funds << funded_t_fund
      create(:virtual_machine_template,
             appliance_type: appliance_type,
             tenants: [default_t])
      create(:virtual_machine_template,
             appliance_type: appliance_type,
             tenants: [funded_t])

      Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute

      expect(appliance.fund.reload).not_to eq funded_t_fund.reload
      expect(appliance.fund).to eq u.default_fund
    end

    it 'does not assign a fund which is incompatible with selected tenants' do
      f1 = create(:fund)
      f2 = create(:fund)
      t1 = create(:openstack_with_flavors, funds: [f1])
      t2 = create(:openstack_with_flavors, funds: [f2])
      user = create(:user, funds: [f1, f2])
      vmt = create(:virtual_machine_template, tenants: [t1, t2])
      at = create(:appliance_type, virtual_machine_templates: [vmt])
      as = create(:appliance_set, user: user)
      t1_a = create(
        :appliance,
        appliance_set: as,
        appliance_type: at,
        fund: nil,
        tenants: [t1]
      )
      t2_a = create(
        :appliance,
        appliance_set: as,
        appliance_type: at,
        fund: nil,
        tenants: [t2]
      )

      Atmosphere::Cloud::SatisfyAppliance.new(t1_a).execute
      Atmosphere::Cloud::SatisfyAppliance.new(t2_a).execute

      expect(t1_a.fund).to eq f1
      expect(t2_a.fund).to eq f2
    end
  end

  context 'new appliance created' do
    context 'development mode' do
      let(:dev_appliance_set) { create(:dev_appliance_set, user: u) }
      let(:config_inst) { create(:appliance_configuration_instance) }
      it 'does not reuse available vm' do
        tmpl_of_shareable_at
        appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
        appl2 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)

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
        appl1 = create(:appliance, appliance_set: dev_appliance_set, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
        appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)

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

      context 'dev mode properties' do
        let(:amazon) { create(:amazon_with_flavors, funds: [fund]) }

        let!(:at) do
          create(:appliance_type, preference_cpu: 2).tap do |at|
            create(:virtual_machine_template,
                   tenants: [amazon], appliance_type: at)
          end
        end

        let(:appl_vm_manager) do
          double('appliance_vms_manager',
                 can_reuse_vm?: false,
                 save: true)
        end

        let(:appliance) do
          create(:appliance,
                 appliance_type: at, appliance_set: dev_appliance_set,
                 fund: fund, tenants: Atmosphere::Tenant.all)
        end

        let(:dev_mode_property_set) { appliance.dev_mode_property_set }

        before do
          allow(Atmosphere::ApplianceVmsManager).
            to receive(:new).
            and_return(appl_vm_manager)
        end

        it 'uses AT prefferences when not set in appliance' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.cpu).to eq 2
          end

          described_class.new(appliance).execute
        end

        it 'takes dev mode preferences memory into account' do
          dev_mode_property_set.preference_memory = 4000

          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.memory).to be >= 4000
          end

          described_class.new(appliance).execute
        end

        it 'takes dev mode preferences cpu into account' do
          dev_mode_property_set.preference_cpu = 4

          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.cpu).to eq 4
          end

          described_class.new(appliance).execute
        end

        it 'takes dev mode preferences disk into account' do
          dev_mode_property_set.preference_disk = 600

          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.hdd).to be >= 600
          end

          described_class.new(appliance).execute
        end
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
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, _, n|
            expect(n).to eq name
          end

          appl = create(:appliance, appliance_set: dev_appliance_set,
                        appliance_type: shareable_appl_type, name: name,
                        fund: fund, tenants: Atmosphere::Tenant.all)

          described_class.new(appl).execute
        end

        it 'to appliance type name if appliance name is blank' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, _, n|
            expect(n).to eq shareable_appl_type.name
          end

          appl = create(:appliance, name: nil, appliance_set: dev_appliance_set,
                        appliance_type: shareable_appl_type, fund: fund,
                        tenants: Atmosphere::Tenant.all)

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
          appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, tenants: Atmosphere::Tenant.all)

          described_class.new(appl).execute

          vms = Atmosphere::VirtualMachine.all
          expect(vms.size).to eql 1
          vm = vms.first
          expect(vm.appliances.size).to eql 1
          expect(vm.appliances).to include appl
        end

        it 'sets appliance state to satisfied if vm was instantiated' do
          appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, tenants: Atmosphere::Tenant.all)

          described_class.new(appl).execute

          appl.reload
          expect(appl.state).to eql 'satisfied'
        end

        it 'does not reuse avaiable vm if appliances use config with equal payload and different ids' do
          tmpl_of_shareable_at
          config_inst = create(:appliance_configuration_instance)
          appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
          appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance, payload: config_inst.payload), fund: fund, tenants: Atmosphere::Tenant.all)

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
            appl1 = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)
            appl2 = create(:appliance, appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all)

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
        let!(:appl1) do
          create(
            :appliance,
            appliance_set: wf,
            appliance_type: shareable_appl_type,
            appliance_configuration_instance: config_inst,
            tenants: Atmosphere::Tenant.all
          )
        end
        let(:appl2) do
          create(
            :appliance,
            appliance_set: wf2,
            appliance_type: shareable_appl_type,
            appliance_configuration_instance: config_inst,
            tenants: Atmosphere::Tenant.all
          )
        end

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

          it 'sets correct fund for appl2 to satisfied if vm was reused' do
            expect(appl2.fund).to eql fund
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
      let(:t) { create(:openstack_with_flavors, funds: [fund]) }
      let!(:tmpl_of_not_shareable_at) { create(:virtual_machine_template, appliance_type: not_shareable_appl_type, tenants: [t])}
      let(:config_inst) { create(:appliance_configuration_instance) }
      let!(:appl1) { create(:appliance, appliance_set: wf, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all) }
      let(:appl2) { create(:appliance, appliance_set: wf2, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst, fund: fund, tenants: Atmosphere::Tenant.all) }

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

    context 'when one of tenant with VMTs is turned off' do
      it 'failed when all VMTs are on inactive tenant' do
        tenant = create(:tenant, active: false, funds: [fund])
        inactive_vmt = create(:virtual_machine_template, tenants: [tenant])
        at = create(:appliance_type, virtual_machine_templates: [inactive_vmt])
        appl = create(
          :appliance,
          appliance_set: wf,
          appliance_type: at,
          fund: nil
        )

        described_class.new(appl).execute

        expect(appl.state).to eql 'unsatisfied'
        expect(appl.state_explanation).to start_with 'No matching template'
      end

      it 'chooses VMT from active tenant' do
        inactive_t, inactive_vmt = vmt_on_tenant(t_active: false)
        active_t, active_vmt = vmt_on_tenant(t_active: true)
        fund.tenants << inactive_t << active_t
        flavor = create(:virtual_machine_flavor,
          tenant: active_t, id_at_site: '123')
        allow(Atmosphere::BillingService).to receive(:can_afford_flavor?)
          .with(anything, flavor).and_return(true)
        at = create(:appliance_type,
          virtual_machine_templates: [inactive_vmt, active_vmt])
        appl = create(:appliance,
                      appliance_set: wf, appliance_type: at,
                      tenants: [inactive_t, active_t], fund: fund)

        described_class.new(appl).execute
        selected_vmt = appl.virtual_machines.first.source_template

        expect(appl.state).to eql 'satisfied'
        expect(selected_vmt).to eql active_vmt
      end
    end

    context 'when one of the flavor is turned off' do
      it 'failed when there is not active flavor' do
        t, vmt = vmt_on_tenant(t_active: true)
        fund.tenants << t
        create(:flavor, active: false, tenant: t)
        at = create(:appliance_type, virtual_machine_templates: [vmt])
        appl = create(:appliance, appliance_set: wf,
                      appliance_type: at, tenants: [t], fund: fund)

        described_class.new(appl).execute

        expect(appl.state).to eql 'unsatisfied'
        expect(appl.state_explanation).to start_with 'No matching flavor'
      end

      it 'chooses VMT with active flavor' do
        t, vmt = vmt_on_tenant(t_active: true)
        fund.tenants << t
        create(:flavor, active: false, tenant: t)
        active_flavor = create(:flavor,
            active: true,
            tenant: t,
            id_at_site: '123'
          )
        at = create(:appliance_type, virtual_machine_templates: [vmt])
        allow(Atmosphere::BillingService).to receive(:can_afford_flavor?)
          .with(anything, active_flavor).and_return(true)
        appl = create(:appliance, appliance_set: wf,
                      appliance_type: at, tenants: [t], fund: fund)

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
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, tenants: Atmosphere::Tenant.all)

      described_class.new(appl).execute
      appl.reload

      expect(appl.state).to eql 'unsatisfied'
    end

    it 'sets state explanation' do
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, tenants: Atmosphere::Tenant.all)

      described_class.new(appl).execute
      appl.reload

      expect(appl.state_explanation).to start_with "No matching template"
    end

    it 'only saving tmpl exists' do
      saving_tmpl = create(:virtual_machine_template, appliance_type: at, state: :saving)
      appl = create(:appliance, appliance_set: wf, appliance_type: at, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, tenants: Atmosphere::Tenant.all)

      described_class.new(appl).execute
      appl.reload

      expect(appl.state).to eql 'unsatisfied'
    end
  end

  context 'flavor' do
    let(:appl_type) { create(:appliance_type, preference_memory: 1024, preference_cpu: 2) }
    let(:appl_vm_manager) do
      double('appliance_vms_manager',
        :can_reuse_vm? => false,
        save: true
      )
    end
    let(:amazon) { create(:amazon_with_flavors, funds: [fund]) }

    it 'includes flavor in params of created vm' do
      allow(Atmosphere::VirtualMachine).to receive(:create)
      allow(Atmosphere::ApplianceVmsManager).to receive(:new).and_return(appl_vm_manager)
      selected_flavor = Atmosphere::Optimizer.
                        instance.select_tmpl_and_flavor_and_tenant([tmpl_of_shareable_at]).
                        last
      appl = create(:appliance, appliance_set: wf, appliance_type: shareable_appl_type, fund: fund, tenants: Atmosphere::Tenant.all)

      expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
        expect(flavor).to eq selected_flavor
      end

      described_class.new(appl).execute
    end

    context 'is selected optimaly' do
      context 'appliance type preferences specified' do

        let(:tmpl_at_amazon) { create(:virtual_machine_template, tenants: [amazon], appliance_type: appl_type) }
        let(:tmpl_at_openstack) { create(:virtual_machine_template, tenants: [openstack], appliance_type: appl_type) }

        context 'preferences exceeds resources of avaiable flavors' do

          before do
            appl_type.preference_cpu = 64
            appl_type.save
          end

          it 'sets state explanation' do
            [tmpl_at_amazon, tmpl_at_openstack]
            appl = create(:appliance, appliance_set: wf, appliance_type: appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), name: 'my service', fund: fund, tenants: Atmosphere::Tenant.all)

            described_class.new(appl).execute

            expect(appl.state_explanation).to start_with "No matching flavor"
          end

          it 'sets appliance as unsatisfied' do
            appl = create(:appliance, appliance_set: wf, appliance_type: appl_type, appliance_configuration_instance: create(:appliance_configuration_instance), fund: fund, tenants: Atmosphere::Tenant.all)

            described_class.new(appl).execute

            expect(appl.state).to eq 'unsatisfied'
          end
        end
      end

      context 'optimizer respects appliance-tenant binding' do
        let(:t1) { create(:openstack_with_flavors, funds: [fund]) }
        let(:t2) { create(:openstack_with_flavors, funds: [fund]) }
        let(:vmt1_1) { create(:virtual_machine_template, tenants: [t1])}
        let(:vmt2_1) { create(:virtual_machine_template, tenants: [t1])}
        let(:vmt2_2) { create(:virtual_machine_template, tenants: [t2])}
        let(:wf_set_2) { create(:appliance_set, appliance_set_type: 'workflow', user: u) }
        let(:at_with_tenant) { create(:appliance_type, visible_to: :all, virtual_machine_templates: [vmt1_1]) }
        let(:at_with_two_tenants) { create(:appliance_type, visible_to: :all, virtual_machine_templates: [vmt2_1, vmt2_2]) }
        let(:a1_unrestricted) { create(:appliance, appliance_set: wf_set_2, appliance_type: at_with_tenant, tenants: [t1, t2]) }
        let(:a1_restricted_unsatisfiable) { create(:appliance, appliance_set: wf_set_2, appliance_type: at_with_tenant, tenants: [t2]) }

        let!(:vmt3) { create(:virtual_machine_template, tenants: [t2], managed_by_atmosphere: true)}
        let!(:shareable_at) { create(:appliance_type, visible_to: :all, shared: true, virtual_machine_templates: [vmt3]) }
        let!(:wf_set_1) { create(:appliance_set, appliance_set_type: 'workflow', user: u) }
        let!(:vm_shared) { create(:virtual_machine, source_template: vmt3, tenant: t2, managed_by_atmosphere: true)}
        let!(:a_shared) { create(:appliance, appliance_set: wf_set_1, appliance_type: shareable_at, tenants: [t2], virtual_machines: [vm_shared])}

        it 'spawns a vm for an unrestricted appliance' do
          appl = create(:appliance, appliance_set: wf_set_2, appliance_type: at_with_tenant, fund: fund, tenants: [t1, t2])

          described_class.new(appl).execute

          expect(appl.state).to eq "satisfied"
          expect(appl.virtual_machines.count).to eq 1
        end

        it 'unable to spawn vm for a restricted appliance' do
          appl = create(:appliance, appliance_set: wf_set_2, appliance_type: at_with_tenant, fund: fund, tenants: [t2])

          described_class.new(appl).execute

          expect(appl.state).to eq "unsatisfied"
          expect(appl.virtual_machines.count).to eq 0
        end

        it 'spawns vm for a restricted appliance when there are matching templates' do
          appl = create(:appliance, appliance_set: wf_set_2, appliance_type: at_with_two_tenants, fund: fund, tenants: [t2])

          described_class.new(appl).execute

          expect(appl.state).to eq "satisfied"
          expect(appl.virtual_machines.count).to eq 1
        end

        it 'reuses vm which satisfies appliance restrictions' do
          appl = create(:appliance, appliance_set: wf_set_2, appliance_type: shareable_at, fund: fund, tenants: [t2], appliance_configuration_instance: a_shared.appliance_configuration_instance)

          described_class.new(appl).execute

          expect(appl.state).to eq "satisfied"
          expect(appl.virtual_machines.count).to eq 1
          expect(appl.virtual_machines.first).to eq vm_shared
        end

        it 'does not reuse vm which violates appliance restrictions' do
          appl = create(:appliance, appliance_set: wf_set_2, appliance_type: shareable_at, fund: fund, tenants: [t1], appliance_configuration_instance: a_shared.appliance_configuration_instance)

          described_class.new(appl).execute

          expect(appl.state).to eq "unsatisfied"
          expect(appl.virtual_machines.count).to eq 0
        end
      end
    end

    context 'dev mode properties' do
      let(:at) { create(:appliance_type, preference_memory: 1024, preference_cpu: 2) }
      let!(:vmt) { create(:virtual_machine_template, tenants: [amazon], appliance_type: at) }
      let(:as) { create(:appliance_set, appliance_set_type: :development, user: u) }

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

      context 'when preferences are not set in appliance' do
        it 'uses preferences from AT' do
          appl = create(:appliance, appliance_type: at, appliance_set: as, fund: fund, tenants: Atmosphere::Tenant.all)

          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.cpu).to eq 2
          end

          described_class.new(appl).execute
        end
      end

      context 'when preferences set in appliance' do
        before do
          @appl = build(:appliance, appliance_type: at, appliance_set: as, fund: fund, tenants: Atmosphere::Tenant.all)
          @appl.dev_mode_property_set = Atmosphere::DevModePropertySet.new(name: 'pref_test')
          @appl.dev_mode_property_set.appliance = @appl
        end

        it 'takes dev mode preferences memory into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.memory).to eq 7680
          end
          @appl.dev_mode_property_set.preference_memory = 4000

          described_class.new(@appl).execute
        end

        it 'takes dev mode preferences cpu into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.cpu).to eq 4
          end
          @appl.dev_mode_property_set.preference_cpu = 4

          described_class.new(@appl).execute
        end

        it 'takes dev mode preferences disk into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, _, flavor, _|
            expect(flavor.hdd).to eq 840
          end
          @appl.dev_mode_property_set.preference_disk = 600

          described_class.new(@appl).execute
        end
      end
    end
  end
end
