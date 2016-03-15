require 'rails_helper'

describe Atmosphere::Cloud::VmDestroyWorker do
  it 'destroy existing VM' do
    vm = create(:virtual_machine)

    expect { subject.perform(vm.id) }.
      to change { Atmosphere::VirtualMachine.count }.by(-1)
  end

  it 'does nothing when VM does not exist' do
    subject.perform('does not exist')
  end
end
