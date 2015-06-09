# == Schema Information
#
# Table name: virtual_machine_flavors
#
#  id                      :integer          not null, primary key
#  flavor_name             :string(255)      not null
#  cpu                     :float
#  memory                  :float
#  hdd                     :float
#  hourly_cost             :integer          not null
#  compute_site_id         :integer
#  id_at_site              :string(255)
#  supported_architectures :string(255)      default("x86_64")
#

require 'rails_helper'

describe Atmosphere::VirtualMachineFlavor do
  context 'supported architectures validation' do
    it "adds 'invalid architexture' error message" do
      fl = build(:virtual_machine_flavor,
          supported_architectures: 'invalid architecture'
        )
      saved = fl.save
      expect(saved).to be false
      expect(fl.errors.messages).to eq({
          supported_architectures: ['is not included in the list']
        })
    end
  end

  context 'architectures' do
    it 'supports both architectures' do
      flavor = build(:flavor, supported_architectures: 'i386_and_x86_64')

      expect(flavor.supports_architecture?('i386')).to be_truthy
      expect(flavor.supports_architecture?('x86_64')).to be_truthy
    end

    it 'supports only i386 architecture' do
      flavor = build(:flavor, supported_architectures: 'i386')

      expect(flavor.supports_architecture?('i386')).to be_truthy
      expect(flavor.supports_architecture?('x86_64')).to be_falsy
    end

    it 'supports only x architecture' do
      flavor = build(:flavor, supported_architectures: 'x86_64')

      expect(flavor.supports_architecture?('i386')).to be_falsy
      expect(flavor.supports_architecture?('x86_64')).to be_truthy
    end

    it 'finds all 386 flavors' do
      f32, _, f_both = flavor_archs_combination

      flavors = Atmosphere::VirtualMachineFlavor.with_arch('i386')

      expect(flavors.count).to eq 2
      expect(flavors).to include f32
      expect(flavors).to include f_both
    end

    it 'finds all 64 flavors' do
      _, f64, f_both = flavor_archs_combination

      flavors = Atmosphere::VirtualMachineFlavor.with_arch('x86_64')

      expect(flavors.count).to eq 2
      expect(flavors).to include f64
      expect(flavors).to include f_both
    end

    def flavor_archs_combination
      f32 = create(:flavor, supported_architectures: 'i386')
      f64 = create(:flavor, supported_architectures: 'x86_64')
      f_both = create(:flavor, supported_architectures: 'i386_and_x86_64')

      [f32, f64, f_both]
    end
  end

  context 'preferences' do
    it 'finds flavor with CPU specified' do
      flavor = to_smal_and_correct_flavor(cpu: 2)

      flavors = Atmosphere::VirtualMachineFlavor.with_prefs(cpu: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    it 'finds flavor with Memory specified' do
      flavor = to_smal_and_correct_flavor(memory: 2)

      flavors = Atmosphere::VirtualMachineFlavor.with_prefs(memory: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    it 'finds flavor with Memory specified' do
      flavor = to_smal_and_correct_flavor(hdd: 2)

      flavors = Atmosphere::VirtualMachineFlavor.with_prefs(hdd: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    it 'finds flavor using complex query' do
      create(:flavor, cpu: 1, memory: 2, hdd: 2)
      create(:flavor, cpu: 2, memory: 1, hdd: 2)
      create(:flavor, cpu: 2, memory: 2, hdd: 1)
      flavor = create(:flavor, cpu: 2, memory: 2, hdd: 2)

      flavors = Atmosphere::VirtualMachineFlavor.with_prefs(cpu: 2, memory: 2, hdd: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    def to_smal_and_correct_flavor(options)
      to_small = options.inject({}) do |hsh, entity|
        hsh[entity.first] = entity.last - 1
        hsh
      end

      create(:flavor, to_small)
      create(:flavor, options)
    end
  end

  context 'cost settings' do
    describe '#remove_hourly_cost_for' do
      let(:flavor) { create(:flavor) }
      let(:os_family) { Atmosphere::OSFamily.first }
      let(:at) { create(:appliance_type, os_family: os_family) }
      let(:vmt) { create(:virtual_machine_template, appliance_type: at) }

      it 'ignores removing nonexistent cost setting' do
        expect(Atmosphere::OSFamily.count).to eq 2
        expect{ flavor.remove_hourly_cost_for(os_family) }.
          not_to raise_error
        expect(flavor.remove_hourly_cost_for(os_family)).to eq nil
      end

      it 'removes set cost by destroying relation object' do
        flavor.set_hourly_cost_for(os_family, 100)
        expect(Atmosphere::FlavorOSFamily.count).to eq 1
        expect{ flavor.remove_hourly_cost_for(os_family) }.
          to change{ Atmosphere::FlavorOSFamily.count }.by(-1)
      end

      it 'prevents removing set cost that affects running VMs' do
        create(:virtual_machine,
               managed_by_atmosphere: true,
               virtual_machine_flavor: flavor,
               source_template: vmt)
        flavor.set_hourly_cost_for(os_family, 100)
        expect(Atmosphere::FlavorOSFamily.count).to eq 1
        expect{ flavor.remove_hourly_cost_for(os_family) }.
          to change{ Atmosphere::FlavorOSFamily.count }.by(0)
      end
    end

    describe 'destroy' do
      let(:flavor) { create(:flavor) }
      let(:os_family) { Atmosphere::OSFamily.first }

      it 'removes all pricing information together with a flavor' do
        flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 100)
        flavor.set_hourly_cost_for(Atmosphere::OSFamily.second, 500)
        expect(Atmosphere::FlavorOSFamily.count).to eq 2
        expect{ flavor.destroy }.
          to change { Atmosphere::FlavorOSFamily.count }.by(-2)
      end

      it 'should never perish when serving a running vm' do
        create(:virtual_machine,
               managed_by_atmosphere: true,
               virtual_machine_flavor: flavor)
        expect(flavor.virtual_machines.count).to eq 1
        expect{ flavor.destroy }.
          to change { Atmosphere::VirtualMachineFlavor.count }.by(0)
      end
    end
  end
end
