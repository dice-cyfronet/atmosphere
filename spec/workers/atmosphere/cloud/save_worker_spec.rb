require 'rails_helper'

describe Atmosphere::Cloud::SaveWorker do
  let(:appl) { create(:appliance) }
  let(:at) { create(:appliance_type) }
  let(:action) do
    action = double
    allow(Atmosphere::Cloud::Save).to receive(:new).and_return(action)

    action
  end

  it 'saves appliance into AT only when appliance and AT are present' do
    expect(action).to receive(:execute)

    subject.perform(appl.id, at.id)
  end

  it 'do nothing when appliance is not found' do
    expect(action).to_not receive(:execute)

    subject.perform('non_existing', at.id)
  end

  it 'do nothing when appliance type is not found' do
    expect(action).to_not receive(:execute)

    subject.perform(appl.id, 'non_existing')
  end
end
