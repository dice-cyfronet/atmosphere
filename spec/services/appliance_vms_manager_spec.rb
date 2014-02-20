require 'spec_helper'

describe ApplianceVmsManager do

  context '#can_reuse_vm?' do

    it 'reuses shared VMs in prod mode' do
      appl = appliance(development: false, shared: true)
      subject = ApplianceVmsManager.new(appl)

      expect(subject.can_reuse_vm?).to be_true
    end

    it 'does not reuse VM in dev mode' do
      appl = appliance(development: true, shared: true)
      subject = ApplianceVmsManager.new(appl)

      expect(subject.can_reuse_vm?).to be_false
    end

    it 'does not reuse not shareable VMs' do
      appl = appliance(development: false, shared: false)
      subject = ApplianceVmsManager.new(appl)

      expect(subject.can_reuse_vm?).to be_false
    end
  end

  def appliance(options)
    double(
      development?: options[:development],
      appliance_type: double(shared: options[:shared])
    )
  end
end