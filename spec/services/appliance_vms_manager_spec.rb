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

  shared_examples 'not_enough_funds' do
    it 'sets state to unsatisfied with explanation message and billing state' do
      expect(appl).to have_received(:state=).with(:unsatisfied)
      expect(appl).to have_received(:state_explanation=)
      expect(appl).to have_received(:billing_state=).with('expired')
    end

    it 'does not update appliance services' do
      expect(updater).to_not have_received(:update)
    end
  end

  context '#reuse_vm!' do
    let(:app_vms) { double('vms', :<< => true) }
    let(:appl) do
      double('appliance',
        virtual_machines: app_vms,
        :state= => true,
        :billing_state= => true,
        :state_explanation= => true
      )
    end
    let(:updater) { double('updater', update: true) }
    let(:updater_class) { double('updater class', new: updater) }
    let(:vm) { double('vm') }

    subject { ApplianceVmsManager.new(appl, updater_class) }

    context 'when user can afford vm' do
      before do
        allow(BillingService).to receive(:can_afford_vm?).with(appl, vm).and_return(true)

        subject.reuse_vm!(vm)
      end

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

    context "when user can't afford vm" do
      before do
        allow(BillingService).to receive(:can_afford_vm?)
          .with(appl, vm).and_return(false)

        subject.reuse_vm!(vm)
      end

      it 'does not add VM to appliance' do
        expect(app_vms).to_not have_received(:<<).with(vm)
      end

      it_behaves_like 'not_enough_funds'
    end
  end

  context '#spawn_vm!' do
    let(:appl) do
      double('appliance',
        :state= => true,
        :billing_state= => true,
        :state_explanation= => true,

        user_data: 'user data',
        user_key: 'user key',

        virtual_machines: double(create: vm)
      )
    end
    let(:updater) { double('updater', update: true) }
    let(:updater_class) { double('updater class', new: updater) }

    let(:vm_creator) { double('vm creator', :spawn_vm! => 'server_id') }
    let(:vm_creator_class) { double('vm creator class') }

    let(:tmpl)   { double('tmpl', compute_site: 'cs') }
    let(:flavor) { 'flavor' }
    let(:name)   { 'name' }
    let(:vm)     { 'vm' }

    subject { ApplianceVmsManager.new(appl, updater_class, vm_creator_class) }

    before do
      allow(vm_creator_class).to receive(:new).with(tmpl,
        {flavor: flavor, name: name, user_data: 'user data', user_key: 'user key'})
          .and_return(vm_creator)
    end

    context 'when user can afford to spawn VM with selected flavor' do
      before do
        allow(BillingService).to receive(:can_afford_flavor?)
          .with(appl, flavor).and_return(true)
      end

      it 'creates new VM' do
        expect(appl.virtual_machines).to receive(:create) do |params|
          expect(params[:name]).to eq name
          expect(params[:source_template]).to eq tmpl
          expect(params[:virtual_machine_flavor]).to eq flavor
          expect(params[:managed_by_atmosphere]).to be_true
          expect(params[:id_at_site]).to eq 'server_id'
          expect(params[:compute_site]).to eq tmpl.compute_site
        end

        subject.spawn_vm!(tmpl, flavor, name)
      end

      it 'sets state to satisfied' do
        expect(appl).to receive(:state=).with(:satisfied)

        subject.spawn_vm!(tmpl, flavor, name)
      end

      it 'updates appliance services with new VM hint' do
        expect(updater).to receive(:update).with({ new_vm: vm })

        subject.spawn_vm!(tmpl, flavor, name)
      end
    end

    context "when user can't afford to spawn VM with selected flavor" do
      before do
        allow(BillingService).to receive(:can_afford_flavor?)
          .with(appl, flavor).and_return(false)

        subject.spawn_vm!(tmpl, flavor, name)
      end

      it 'does not create any new VM' do
        expect(appl.virtual_machines).to_not have_received(:create)
      end

      it_behaves_like 'not_enough_funds'
    end
  end
end