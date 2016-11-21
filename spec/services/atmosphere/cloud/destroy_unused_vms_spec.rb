require 'rails_helper'

describe Atmosphere::Cloud::DestroyUnusedVms do
  it 'destroys only unused vms' do
    used_vm = create(:virtual_machine, managed_by_atmosphere: true)
    unused_vm = create(:virtual_machine, managed_by_atmosphere: true)
    create(:appliance, virtual_machines: [used_vm])

    described_class.new.execute

    expect(Atmosphere::Cloud::VmDestroyWorker).
      to have_enqueued_sidekiq_job(unused_vm.id)
  end
end
