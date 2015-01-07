require 'rails_helper'

describe Atmosphere::ApplianceSetSerializer do
  it 'returns information about set' do
    as = build(:appliance_set,
               id: 1,
               name: 'as',
               priority: 24,
               appliance_set_type: :portal,
               optimization_policy: :manual)
    serializer = Atmosphere::ApplianceSetSerializer.new(as)

    result = JSON.parse(serializer.to_json)

    expect(result['appliance_set']['id']).to eq 1
    expect(result['appliance_set']['name']).to eq 'as'
    expect(result['appliance_set']['priority']).to eq 24
    expect(result['appliance_set']['appliance_set_type']).to eq 'portal'
    expect(result['appliance_set']['optimization_policy']).to eq 'manual'
  end
end
