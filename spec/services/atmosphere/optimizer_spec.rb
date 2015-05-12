require 'rails_helper'

describe Atmosphere::Optimizer do
  include VmtOnCsHelpers

  before do
    Fog.mock!
  end

  let!(:wf) { create(:workflow_appliance_set) }
  let!(:wf2) { create(:workflow_appliance_set) }
  let!(:shareable_appl_type) { create(:shareable_appliance_type) }
  let!(:fund) { create(:fund) }
  let!(:openstack) { create(:openstack_with_flavors, funds: [fund]) }
  let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type, compute_site: openstack)}

  subject { Atmosphere::Optimizer.instance }

  it 'is not nil' do
     expect(subject).not_to be_nil
  end

  context 'virtual machine is applianceless' do
    let!(:external_vm) { create(:virtual_machine) }
    let!(:vm) { create(:virtual_machine, managed_by_atmosphere: true) }

    before do
      servers_double = double
      allow(vm.compute_site.cloud_client)
        .to receive(:servers).and_return(servers_double)
      allow(servers_double).to receive(:destroy)
    end

    it 'terminates unused manageable vm' do
      subject.run(destroyed_appliance: true)

      expect(Atmosphere::Cloud::VmDestroyWorker).to have_enqueued_job(vm.id)
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

    context 'is selected with appropriate architecture' do
      it 'if cheaper flavor does not support architecture' do
        cs = create(:compute_site)
        tmpl_64b = create(:virtual_machine_template, architecture: 'x86_64', appliance_type: appl_type, compute_site: cs)
        fl_32b = create(:virtual_machine_flavor, flavor_name: 'flavor 32', cpu: 2, memory: 1024, hdd: 30, compute_site: cs, supported_architectures: 'i386')
        fl_64b = create(:virtual_machine_flavor, flavor_name: 'flavor 64', cpu: 2, memory: 1024, hdd: 30, compute_site: cs, supported_architectures: 'x86_64')

        fl_32b.set_hourly_cost_for(Atmosphere::OSFamily.first, 10)
        fl_64b.set_hourly_cost_for(Atmosphere::OSFamily.first, 20)

        selected_tmpl, selected_flavor = subject.select_tmpl_and_flavor([tmpl_64b])
        expect(selected_tmpl).to eq tmpl_64b
        expect(selected_flavor).to eq fl_64b
      end
    end

    context 'is selected optimaly' do
      context 'appliance type preferences not specified' do
        it 'selects instance with at least 1.5GB RAM for public compute site' do
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, compute_site: amazon, appliance_type: appl_type)
          selected_tmpl, flavor = subject.select_tmpl_and_flavor([tmpl])
          expect(flavor.memory).to be >= 1536
        end

        it 'selects instance with 512MB RAM for private compute site' do
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, compute_site: openstack, appliance_type: appl_type)
          selected_tmpl, flavor = subject.select_tmpl_and_flavor([tmpl])
          expect(flavor.memory).to be >= 512
        end
      end

      context 'appliance type preferences specified' do
        let(:tmpl_at_amazon) { create(:virtual_machine_template, compute_site: amazon, appliance_type: appl_type) }
        let(:tmpl_at_openstack) { create(:virtual_machine_template, compute_site: openstack, appliance_type: appl_type) }

        it 'selects cheapest flavour that satisfies requirements' do
          selected_tmpl, flavor = subject.select_tmpl_and_flavor([tmpl_at_amazon, tmpl_at_openstack])
          flavor.reload

          expect(flavor.memory).to be >= 1024
          expect(flavor.cpu).to be >= 2
          all_discarded_flavors = amazon.virtual_machine_flavors + openstack.virtual_machine_flavors - [flavor]
          all_discarded_flavors.each {|f|
            f.reload
            if(f.memory >= appl_type.preference_memory and f.cpu >= appl_type.preference_cpu)
              expect(f.get_hourly_cost_for(Atmosphere::OSFamily.first) >= flavor.get_hourly_cost_for(Atmosphere::OSFamily.first)).to be true
            end
          }
        end

        it 'selects flavor with more ram if prices are equal' do
          biggest_os_flavor = openstack.virtual_machine_flavors.max_by {|f| f.memory}
          optimal_flavor = create(:virtual_machine_flavor, memory: biggest_os_flavor.memory + 256, cpu: biggest_os_flavor.cpu, hdd: biggest_os_flavor.hdd, compute_site: amazon)
          biggest_os_flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 100)
          optimal_flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 100)
          amazon.reload
          appl_type.preference_memory = biggest_os_flavor.memory
          appl_type.save

          tmpl, flavor = subject.select_tmpl_and_flavor([tmpl_at_amazon, tmpl_at_openstack])

          expect(flavor).to eq optimal_flavor
          expect(tmpl).to eq tmpl_at_amazon
        end

        context 'preferences exceeds resources of avaiable flavors' do
          it 'returns nil flavor' do
            appl_type.preference_cpu = 64
            appl_type.save

            tmpl, flavor = subject.select_tmpl_and_flavor([tmpl_at_amazon, tmpl_at_openstack])

            expect(flavor).to be_nil
          end
        end
      end
    end

    context 'dev mode properties' do
      let(:at) { create(:appliance_type, preference_memory: 1024, preference_cpu: 2) }
      let!(:vmt) { create(:virtual_machine_template, compute_site: amazon, appliance_type: at) }
      let(:as) { create(:appliance_set, appliance_set_type: :development) }

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
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.cpu).to eq 2
          end

          create(:appliance, appliance_type: at, appliance_set: as, fund: fund, compute_sites: Atmosphere::ComputeSite.all)
        end
      end

      context 'when preferences set in appliance' do
        before do
          @appl = build(:appliance, appliance_type: at, appliance_set: as, fund: fund, compute_sites: Atmosphere::ComputeSite.all)
          @appl.dev_mode_property_set = Atmosphere::DevModePropertySet.new(name: 'pref_test')
          @appl.dev_mode_property_set.appliance = @appl
        end

        it 'takes dev mode preferences memory into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.memory).to eq 7680
          end
          @appl.dev_mode_property_set.preference_memory = 4000

          @appl.save!
        end

        it 'takes dev mode preferences cpu into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.cpu).to eq 4
          end
          @appl.dev_mode_property_set.preference_cpu = 4

          @appl.save!
        end

        it 'takes dev mode preferences disk into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.hdd).to eq 840
          end
          @appl.dev_mode_property_set.preference_disk = 600

          @appl.save!
        end
      end
    end
  end
end
