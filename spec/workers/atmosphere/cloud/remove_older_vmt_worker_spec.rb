require 'rails_helper'

describe Atmosphere::Cloud::RemoveOlderVmtWorker do
  it 'removes older VMT for existing VMT' do
    vmt = create(:virtual_machine_template)
    remove_action = double
    allow(Atmosphere::Cloud::RemoveOlderVmt).
      to receive(:new).and_return(remove_action)

    expect(remove_action).to receive(:execute)

    subject.perform(vmt.id)
  end

  it 'does not invoke remove action for non existing VMT' do
    expect(Atmosphere::Cloud::RemoveOlderVmt).
      to_not receive(:new)

    subject.perform('non_existing')
  end
end
