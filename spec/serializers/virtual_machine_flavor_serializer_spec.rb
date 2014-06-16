require 'spec_helper'

describe VirtualMachineFlavorSerializer do
  it 'sets active flag to true for flavor on active compute site' do
    flavor = flavor_on_cs(cs_active: true, active: true)

    result = serialize(flavor)

    expect(result['virtual_machine_flavor']['active']).to be_true
  end

  it 'sets active flag to true for flavor on inactive compute site' do
    flavor = flavor_on_cs(cs_active: false, active: true)

    result = serialize(flavor)

    expect(result['virtual_machine_flavor']['active']).to be_false
  end

  it 'sets active falg to false for flavor without compute site' do
    flavor = create(:flavor, compute_site: nil, active: true)

    result = serialize(flavor)

    expect(result['virtual_machine_flavor']['active']).to be_false
  end

  it 'sets active flag to false when vm flavor is non active' do
    flavor = flavor_on_cs(cs_active: true, active: false)

    result = serialize(flavor)

    expect(result['virtual_machine_flavor']['active']).to be_false
  end

  def serialize(flavor)
    serializer = VirtualMachineFlavorSerializer.new(flavor)

    JSON.parse(serializer.to_json)
  end

  def flavor_on_cs(options)
    cs = create(:compute_site, active: options[:cs_active])
    create(:flavor, compute_site: cs, active: options[:active])
  end
end