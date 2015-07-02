require 'rails_helper'

describe Atmosphere::VirtualMachineFlavorSerializer do

  context 'activity flag tests' do
    it 'is active on active compute site' do
      flavor = flavor_on_t(t_active: true, active: true)

      result = serialize(flavor)

      expect(result['virtual_machine_flavor']['active']).to be_truthy
    end

    it 'is inactive on inactive compute site' do
      flavor = flavor_on_t(t_active: false, active: true)

      result = serialize(flavor)

      expect(result['virtual_machine_flavor']['active']).to be_falsy
    end

    it 'is inactive when not bound to compute site' do
      flavor = create(:flavor, tenant: nil, active: true)

      result = serialize(flavor)

      expect(result['virtual_machine_flavor']['active']).to be_falsy
    end

    it 'sets active flag to false when flavor is inactive' do
      flavor = flavor_on_t(t_active: true, active: false)

      result = serialize(flavor)

      expect(result['virtual_machine_flavor']['active']).to be_falsy
    end
  end

  context 'hourly cost tests' do

    let(:os_family1) { create(:os_family, name: 'foo') }
    let(:os_family2) { create(:os_family, name: 'bar') }

    let(:vmf1) { create(:flavor) }

    it 'returns proper hourly cost for VMF' do

      vmf1.set_hourly_cost_for(Atmosphere::OSFamily.first, 37)
      vmf1.set_hourly_cost_for(os_family1, 50)
      vmf1.set_hourly_cost_for(os_family2, 25)

      vmf1.reload

      result = serialize(vmf1)

      expect(result['virtual_machine_flavor']['hourly_cost']).to eq 50
      expect(result['virtual_machine_flavor']['cost_map'].count).to eq 3

    end

  end


  def serialize(flavor)
    serializer = Atmosphere::VirtualMachineFlavorSerializer.new(flavor)

    JSON.parse(serializer.to_json)
  end

  def flavor_on_t(options)
    t = create(:tenant, active: options[:t_active])
    create(:flavor, tenant: t, active: options[:active])
  end
end
