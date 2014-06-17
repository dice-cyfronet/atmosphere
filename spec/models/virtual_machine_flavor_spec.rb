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
      fl = build(:virtual_machine_flavor, supported_architectures: 'invalid architecture')
      saved = fl.save
      expect(saved).to be false
      expect(fl.errors.messages).to eq({:supported_architectures => ['is not included in the list']})
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
  end
end
