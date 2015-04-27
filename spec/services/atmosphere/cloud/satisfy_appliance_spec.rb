require 'rails_helper'

describe Atmosphere::Cloud::ScaleAppliance do
  let(:strategy) { double() }
  let(:appliance) { create(:appliance) }
  let(:appl_vm_manager) { double('appliance_vms_manager') }

  before do
    allow(Atmosphere::ApplianceVmsManager).
      to receive(:new).and_return(appl_vm_manager)
    expect(appl_vm_manager).to receive(:save)
    allow(appliance).to receive(:optimization_strategy) { strategy }
  end

  context 'cannot scale manually' do
    it 'blocks manual scaling' do
      expect(strategy).to receive(:can_scale_manually?).and_return(false)
      expect(appl_vm_manager).to receive(:unsatisfied)
      expect(appl_vm_manager).to receive(:save)

      described_class.new(appliance, 2).execute
    end
  end

  context 'can scale manually' do
    before do
      allow(strategy).to receive(:can_scale_manually?).and_return(true)
    end

    let(:vms) { double('vms') }
    let(:vms_to_stop) { double('vms to stop') }
    let(:appl) { double('appliance') }

    it 'runs scaling up' do
      allow(strategy).to receive(:vms_to_start).with(2).and_return(vms)

      expect(appl_vm_manager).to receive(:start_vms!).with(vms)
      expect(appl_vm_manager).to receive(:save)

      described_class.new(appliance, 2).execute
    end

    it 'runs scaling down succesfully' do
      allow(strategy).to receive(:vms_to_stop).with(2).and_return(vms_to_stop)
      allow(vms_to_stop).to receive(:count).and_return(2)
      allow(vms).to receive(:count).and_return(3)
      allow(appliance).to receive(:virtual_machines).and_return(vms)

      expect(appl_vm_manager).to receive(:stop_vms!).with(vms_to_stop)
      expect(appl_vm_manager).to receive(:save)

      described_class.new(appliance, -2).execute
    end

    it 'runs scaling down without enogh vms' do
      allow(strategy).to receive(:vms_to_stop).with(3).and_return(vms_to_stop)
      allow(vms_to_stop).to receive(:count).and_return(3)
      allow(vms).to receive(:count).and_return(3)
      allow(appliance).to receive(:virtual_machines).and_return(vms)
      expect(appl_vm_manager).to receive(:unsatisfied)
      expect(appl_vm_manager).to receive(:save)

      described_class.new(appliance, -3).execute
    end
  end
end
