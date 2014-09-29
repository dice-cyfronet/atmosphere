require 'spec_helper'

describe VmDestroyer do
  let(:vm) { double('vm', appliances: [], destroy: true) }
  let(:updater) { double('updater', update: true) }
  let(:updater_class) { double('updater_class', new: updater) }

  subject { VmDestroyer.new(vm, updater_class) }

  context '#destroy' do
    it 'destroys VM' do
      expect(vm).to receive(:destroy)

      subject.destroy
    end

    it 'pass first args to destroy method' do
      expect(vm).to receive(:destroy).with('param')

      subject.destroy('param')
    end

    it 'returns destroy status' do
      destroy_status = 'destroy status'
      expect(vm).to receive(:destroy).and_return destroy_status

      expect(subject.destroy).to eq destroy_status
    end

    it 'updates affected appliances' do
      appl1, appl2 = double, double
      appl1_updater, appl2_updater = double, double
      allow(vm).to receive(:appliances).and_return([appl1, appl2])

      expect(updater_class).to receive(:new).with(appl1).and_return(appl1_updater)
      expect(updater_class).to receive(:new).with(appl2).and_return(appl2_updater)

      expect(appl1_updater).to receive(:update).once
      expect(appl2_updater).to receive(:update).once

      subject.destroy
    end

    it 'does not update affected appliances when VM not deleted' do
      allow(vm).to receive(:destroy).and_return(false)
      expect(updater_class).to_not receive(:new)

      subject.destroy
    end

    it 'returns errors from vm' do
      error_description = 'error description'
      expect(vm).to receive(:errors).and_return(error_description)

      expect(subject.errors).to eq error_description
    end
  end
end