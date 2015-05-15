require 'rails_helper'

describe Atmosphere::DestroyAppliance do
  let!(:appliance) { create(:appliance) }

  let(:billing_service) do
    double(bill_appliance: true)
  end

  let(:vm_cleaner) do
    double(Atmosphere::Cloud::DestroyUnusedVms, new: double(execute: true))
  end

  subject do
    Atmosphere::DestroyAppliance.
      new(appliance, billing_service: billing_service, vm_cleaner: vm_cleaner)
  end

  it 'bills appliance' do
    expect(billing_service).
      to receive(:bill_appliance).
      with(appliance, anything(), anything(), false)

    subject.execute
  end

  it 'removes appliance' do
    expect { subject.execute }.to change { Atmosphere::Appliance.count }.by(-1)
  end

  it 'cleans unused vms' do
    cleaner = instance_double(Atmosphere::Cloud::DestroyUnusedVms)
    expect(cleaner).to receive(:execute)
    expect(vm_cleaner).to receive(:new).and_return(cleaner)

    subject.execute
  end
end
