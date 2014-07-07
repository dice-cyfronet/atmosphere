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

describe VirtualMachineFlavor do
  context 'supported architectures validation' do
    it "adds 'invalid architexture' error message" do
      fl = build(:virtual_machine_flavor,
          supported_architectures: 'invalid architecture'
        )
      saved = fl.save
      expect(saved).to be false
      expect(fl.errors.messages).to eq({
          :supported_architectures => ['is not included in the list']
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

      flavors = VirtualMachineFlavor.with_arch('i386')

      expect(flavors.count).to eq 2
      expect(flavors).to include f32
      expect(flavors).to include f_both
    end

    it 'finds all 64 flavors' do
      _, f64, f_both = flavor_archs_combination

      flavors = VirtualMachineFlavor.with_arch('x86_64')

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

      flavors = VirtualMachineFlavor.with_prefs(cpu: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    it 'finds flavor with Memory specified' do
      flavor = to_smal_and_correct_flavor(memory: 2)

      flavors = VirtualMachineFlavor.with_prefs(memory: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    it 'finds flavor with Memory specified' do
      flavor = to_smal_and_correct_flavor(hdd: 2)

      flavors = VirtualMachineFlavor.with_prefs(hdd: 2)

      expect(flavors.count).to eq 1
      expect(flavors.first).to eq flavor
    end

    it 'finds flavor using complex query' do
      create(:flavor, cpu: 1, memory: 2, hdd: 2)
      create(:flavor, cpu: 2, memory: 1, hdd: 2)
      create(:flavor, cpu: 2, memory: 2, hdd: 1)
      flavor = create(:flavor, cpu: 2, memory: 2, hdd: 2)

      flavors = VirtualMachineFlavor.with_prefs(cpu: 2, memory: 2, hdd: 2)

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
end
