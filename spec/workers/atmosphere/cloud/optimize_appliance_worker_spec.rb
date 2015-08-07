require 'rails_helper'

describe Atmosphere::Cloud::OptimizeApplianceWorker do
  it 'run optimize process' do
    appliance = create(:appliance)

    service = instance_double(Atmosphere::Cloud::SatisfyAppliance)
    allow(Atmosphere::Cloud::SatisfyAppliance).
      to receive(:new).with(appliance).
      and_return(service)

    expect(service).to receive(:execute)

    subject.perform(appliance.id)
  end

  it 'do nothing when appliance is not found' do
    expect(Atmosphere::Cloud::SatisfyAppliance).
      to_not receive(:new)

    subject.perform('non_existing')
  end
end
