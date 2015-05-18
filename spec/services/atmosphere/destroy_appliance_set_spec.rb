require 'rails_helper'

describe Atmosphere::DestroyApplianceSet do
  it 'removes appliance set' do
    as = create(:appliance_set)
    expect { Atmosphere::DestroyApplianceSet.new(as).execute }.
      to change { Atmosphere::ApplianceSet.count }.by(-1)
  end

  it 'removes connected appliances' do
    appl1, appl2 = build(:appliance), build(:appliance)
    as = build(:appliance_set, appliances: [appl1, appl2])

    expect_appliance_destroy(appl1)
    expect_appliance_destroy(appl2)

    Atmosphere::DestroyApplianceSet.new(as).execute
  end

  def expect_appliance_destroy(appliance)
    destroyer = double('appliance destroyer')
    expect(destroyer).to receive(:execute).and_return(true)
    expect(Atmosphere::DestroyAppliance).
      to receive(:new).with(appliance).
      and_return(destroyer)
  end
end
