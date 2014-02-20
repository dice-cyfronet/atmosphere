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

  context '#add_vm' do
    let(:app_vms) { double('vms', :<< => true) }
    let(:appl) { double('appliance', virtual_machines: app_vms, :state= => true) }
    let(:updater) { double('updater', update: true) }
    let(:updater_class) { double('updater class', new: updater) }
    let(:vm) { double('vm') }

    subject { ApplianceVmsManager.new(appl, updater_class) }

    before { subject.add_vm(vm) }

    it 'adds VM to appliance' do
      expect(app_vms).to have_received(:<<).with(vm)
    end

    it 'sets state to satisfied' do
      expect(appl).to have_received(:state=).with(:satisfied)
    end

    it 'updates appliance services with new VM hint' do
      expect(updater).to have_received(:update).with({ new_vm: vm })
    end
  end
end