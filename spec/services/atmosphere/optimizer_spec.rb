require 'rails_helper'

describe Atmosphere::Optimizer do
  include VmtOnTHelpers

  before do
    Fog.mock!
  end

  let!(:fund) { create(:fund) }
  let!(:openstack) { create(:openstack_with_flavors, funds: [fund]) }
  let!(:u) { create(:user, funds: [fund]) }
  let!(:wf) { create(:workflow_appliance_set, user: u) }
  let!(:wf2) { create(:workflow_appliance_set, user: u) }
  let!(:shareable_appl_type) { create(:shareable_appliance_type) }
  let!(:tmpl_of_shareable_at) do
    create(:virtual_machine_template,
           appliance_type: shareable_appl_type, tenants: [openstack])
  end

  subject { Atmosphere::Optimizer.instance }

  it 'is not nil' do
    expect(subject).not_to be_nil
  end

  context 'flavor' do
    let(:appl_type) do
      create(:appliance_type, preference_memory: 1024, preference_cpu: 2)
    end
    let(:amazon) { create(:amazon_with_flavors, funds: [fund]) }

    context 'is selected with appropriate architecture' do
      it 'if cheaper flavor does not support architecture' do
        t = create(:tenant)
        tmpl_64b = create(:virtual_machine_template,
                          architecture: 'x86_64',
                          appliance_type: appl_type, tenants: [t])
        fl_32b = create(:virtual_machine_flavor,
                        flavor_name: 'flavor 32', cpu: 2,
                        memory: 1024, hdd: 30, tenant: t,
                        supported_architectures: 'i386')
        fl_64b = create(:virtual_machine_flavor,
                        flavor_name: 'flavor 64',
                        cpu: 2, memory: 1024, hdd: 30, tenant: t,
                        supported_architectures: 'x86_64')

        fl_32b.set_hourly_cost_for(Atmosphere::OSFamily.first, 10)
        fl_64b.set_hourly_cost_for(Atmosphere::OSFamily.first, 20)

        selected_tmpl, selected_tenant, selected_flavor =
          subject.select_tmpl_and_flavor_and_tenant([tmpl_64b])
        expect(selected_tmpl).to eq tmpl_64b
        expect(selected_tenant).to eq t
        expect(selected_flavor).to eq fl_64b
      end
    end

    context 'is selected optimally' do
      context 'appliance type preferences not specified' do
        it 'selects instance with at least 1.5GB RAM for public tenant' do
          appl_type = create(:appliance_type)
          tmpl = create(:virtual_machine_template,
                       tenants: [amazon], appliance_type: appl_type)
          _, _, flavor = subject.select_tmpl_and_flavor_and_tenant([tmpl])

          expect(flavor.memory).to be >= 1536
        end

        it 'selects instance with 512MB RAM for private tenant' do
          appl_type = create(:appliance_type)
          tmpl = create(:virtual_machine_template,
                       tenants: [openstack], appliance_type: appl_type)
          _, _, flavor = subject.select_tmpl_and_flavor_and_tenant([tmpl])

          expect(flavor.memory).to be >= 512
        end
      end

      context 'appliance type preferences specified' do
        let(:tmpl_at_amazon) do
          create(:virtual_machine_template,
                 tenants: [amazon], appliance_type: appl_type)
        end
        let(:tmpl_at_openstack) do
          create(:virtual_machine_template,
                 tenants: [openstack], appliance_type: appl_type)
        end

        it 'selects cheapest flavour that satisfies requirements' do
          _, _, flavor = subject.
                         select_tmpl_and_flavor_and_tenant([tmpl_at_amazon,
                                                            tmpl_at_openstack])
          flavor.reload

          expect(flavor.memory).to be >= 1024
          expect(flavor.cpu).to be >= 2
          all_discarded_flavors = amazon.virtual_machine_flavors +
                                  openstack.virtual_machine_flavors - [flavor]
          all_discarded_flavors.each do |f|
            f.reload
            if f.memory >= appl_type.preference_memory &&
               f.cpu >= appl_type.preference_cpu
              expect(f.get_hourly_cost_for(Atmosphere::OSFamily.first) >= \
                flavor.get_hourly_cost_for(Atmosphere::OSFamily.first)).
                to be_truthy
            end
          end
        end

        it 'selects flavor with more ram if prices are equal' do
          biggest_os_flavor = openstack.virtual_machine_flavors.max_by(&:memory)
          optimal_flavor = create(:virtual_machine_flavor,
                                  memory: biggest_os_flavor.memory + 256,
                                  cpu: biggest_os_flavor.cpu,
                                  hdd: biggest_os_flavor.hdd,
                                  tenant: amazon)
          biggest_os_flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 1)
          optimal_flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 1)
          amazon.reload
          appl_type.preference_memory = biggest_os_flavor.memory
          appl_type.save

          tmpl, _, flavor =
            subject.select_tmpl_and_flavor_and_tenant([tmpl_at_amazon,
                                                       tmpl_at_openstack])

          expect(flavor).to eq optimal_flavor
          expect(tmpl).to eq tmpl_at_amazon
        end

        context 'preferences exceeds resources of available flavors' do
          it 'returns nil flavor' do
            appl_type.preference_cpu = 64
            appl_type.save

            _, _, flavor =
              subject.select_tmpl_and_flavor_and_tenant([tmpl_at_amazon,
                                                         tmpl_at_openstack])

            expect(flavor).to be_nil
          end
        end
      end
    end
  end

  context 'selection is quick' do
    it 'selects template, flavor and tenant quickly' do
      vmts = []
      100.times do
        atype = create(:appliance_type)
        t = create(:openstack_with_flavors, funds: [fund])
        vmts << create(
          :virtual_machine_template,
          appliance_type: atype,
          tenants: [t]
        )
      end
      t1 = Time.now.to_f
      subject.select_tmpl_and_flavor_and_tenant(vmts)
      t2 = Time.now.to_f
      expect(t2 - t1).to be < 5,
                         'Flavor selection process took longer than 5 seconds'
    end
  end

  context 'selection acknowledges user-tenant relationship through funds' do
    let(:u1) { create(:user) }
    let(:u2) { create(:user) }
    let(:t1) { create(:openstack_with_flavors) }
    let(:t2) { create(:openstack_with_flavors) }
    let(:f1) { create(:fund, tenants: [t1]) }
    let(:f2) { create(:fund, tenants: [t2]) }
    let(:vmt1) { create(:virtual_machine_template, tenants: [t1]) }
    let(:vmt2) { create(:virtual_machine_template, tenants: [t2]) }
    let(:atype) do
      create(:appliance_type,
             virtual_machine_templates: [vmt1, vmt2], preference_cpu: 8)
    end

    before do
      u1.funds = [f1]
      u2.funds = [f2]
      @aset1 = create(:appliance_set, user: u1)
      @aset2 = create(:appliance_set, user: u2)
      @a1 = create(:appliance,
                   appliance_set: @aset1, appliance_type: atype,
                   fund: f1, tenants: [t1, t2])
      @a2 = create(:appliance,
                   appliance_set: @aset2, appliance_type: atype,
                   fund: f2, tenants: [t1, t2])
      @opt_strategy_for_a1 = Atmosphere::OptimizationStrategy::Default.new(@a1)
      @opt_strategy_for_a2 = Atmosphere::OptimizationStrategy::Default.new(@a2)
    end

    it 'selects for user with one fund assignment' do
      tmpls1 = @opt_strategy_for_a1.new_vms_tmpls_and_flavors_and_tenants
      tmpls2 = @opt_strategy_for_a2.new_vms_tmpls_and_flavors_and_tenants
      expect(tmpls1.first[:template]).to eq vmt1
      expect(tmpls1.first[:flavor]).
        to eq Atmosphere::VirtualMachineFlavor.find_by(tenant: t1,
                                                       id_at_site: '5')
      expect(tmpls1.first[:tenant]).to eq t1
      expect(tmpls2.first[:template]).to eq vmt2
      expect(tmpls2.first[:flavor]).
        to eq Atmosphere::VirtualMachineFlavor.find_by(tenant: t2,
                                                       id_at_site: '5')
      expect(tmpls2.first[:tenant]).to eq t2
    end

    it 'selects for user with multiple fund assignments' do
      # Make t2 flavors expensive compared to t1 flavors
      t2.virtual_machine_flavors.map(&:flavor_os_families).
        flatten.uniq.compact.each do |fof|
          fof.hourly_cost *= 1000
          fof.save
        end

      # Add a new user with access to all tenants and an empty user
      u3 = create(:user, funds: [f1, f2])
      aset3 = create(:appliance_set, user: u3)
      a3 = create(:appliance,
                  appliance_set: aset3, appliance_type: atype,
                  fund: f1, tenants: [t1, t2])
      opt_strategy_for_a3 = Atmosphere::OptimizationStrategy::Default.new(a3)
      tmpls3 = opt_strategy_for_a3.new_vms_tmpls_and_flavors_and_tenants

      expect(tmpls3.first[:flavor]).
        to eq Atmosphere::VirtualMachineFlavor.find_by(tenant: t1,
                                                       id_at_site: '5')
      expect(tmpls3.first[:tenant]).to eq t1
    end

    it 'selects for user with no fund assignments' do
      u4 = create(:user, funds: [])
      aset4 = create(:appliance_set, user: u4)
      a4 = create(:appliance,
                  appliance_set: aset4, appliance_type: atype, fund: f1)
      opt_strategy_for_a4 = Atmosphere::OptimizationStrategy::Default.new(a4)
      tmpls4 = opt_strategy_for_a4.new_vms_tmpls_and_flavors_and_tenants

      expect(tmpls4.first[:flavor]).to be_nil
      expect(tmpls4.first[:tenant]).to be_nil
    end
  end
end
