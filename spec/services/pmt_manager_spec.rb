require 'spec_helper'

describe PmtManager do

  let(:pmt) { double('pmt', save!: true) }
  let(:updater) { double('updater') }
  let(:updater_class) { double(new: updater) }

  subject { PmtManager.new(pmt, updater_class) }

  context '#save!' do
    it 'saves PMT' do
      allow(Appliance).to receive(:with_pmt).with(pmt).and_return([])
      expect(pmt).to receive(:save!)

      subject.save!
    end

    it 'invokes updater on all affected appliances' do
      expect_appliance_update

      subject.save!
    end
  end

  context '#destroy' do
    it 'destroys PMT' do
      allow(Appliance).to receive(:with_pmt).with(pmt).and_return([])
      expect(pmt).to receive(:destroy)

      subject.destroy
    end

    it 'pass destroyed status' do
      allow(Appliance).to receive(:with_pmt).with(pmt).and_return([])
      destroyed = "destroyed status"
      expect(pmt).to receive(:destroy).and_return(destroyed)

      expect(subject.destroy).to eq destroyed
    end

    it 'invokes updater on all affected appliances when pmt destroyed' do
      expect(pmt).to receive(:destroy).and_return(true)
      expect_appliance_update

      subject.destroy
    end

    it 'does not update affected appliances when destroy failed' do
      allow(Appliance).to receive(:with_pmt).with(pmt).and_return(['appl'])
      expect(pmt).to receive(:destroy).and_return(false)
      expect(updater_class).to_not receive(:new)

      subject.destroy
    end
  end

  context '#update!' do
    it 'updates pmt' do
      allow(Appliance).to receive(:with_pmt).with(pmt).and_return([])
      expect(pmt).to receive(:update_attributes!).with('params')

      subject.update!('params')
    end

    it 'updates affected appliances on success' do
      expect(pmt).to receive(:update_attributes!).with('params')
      expect_appliance_update

      subject.update!('params')
    end

    it 'does not updates affected appliances when update failed' do
      allow(Appliance).to receive(:with_pmt).with(pmt).and_return(['appl'])
      expect(pmt).to receive(:update_attributes!).and_raise(Exception.new)
      expect(updater_class).to_not receive(:new)

      expect {
        subject.update!('params')
      }.to raise_error(Exception)
    end
  end

  def expect_appliance_update
    appl1, appl2 = 'appl1', 'appl2'
    allow(Appliance).to receive(:with_pmt).with(pmt).and_return([appl1, appl2])

    appl1_updater, appl2_updater = double, double
    expect(appl1_updater).to receive(:update)
    expect(updater_class).to receive(:new).with(appl1).and_return(appl1_updater)
    expect(appl2_updater).to receive(:update)
    expect(updater_class).to receive(:new).with(appl2).and_return(appl2_updater)
  end
end