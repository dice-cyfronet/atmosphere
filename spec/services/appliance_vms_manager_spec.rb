require 'spec_helper'

describe ApplianceVmsManager do

  context '#can_reuse_vm?' do

    it 'reuses shared VMs in prod mode' do
      appl = appliance(development: false, shared: true)
      subject = ApplianceVmsManager.new(appl)

      expect(subject.can_reuse_vm?).to be_truthy
    end

    it 'does not reuse VM in dev mode' do
      appl = appliance(development: true, shared: true)
      subject = ApplianceVmsManager.new(appl)

      expect(subject.can_reuse_vm?).to be_falsy
    end

    it 'does not reuse not shareable VMs' do
      appl = appliance(development: false, shared: false)
      subject = ApplianceVmsManager.new(appl)

      expect(subject.can_reuse_vm?).to be_falsy
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
    let(:tags_mng) { double('tags manager') }
    let(:tags_manager_class) { double('tags manager class', new: tags_mng) }
    let(:updater) { double('updater', update: true) }
    let(:updater_class) { double('updater class', new: updater) }
    let(:vm) { double('vm') }
    subject { ApplianceVmsManager.new(appl, updater_class, Cloud::VmCreator, tags_manager_class) }

    context 'when user can afford vm' do
      before do
        allow(BillingService).to receive(:can_afford_vm?).with(appl, vm).and_return(true)
        allow(tags_mng).to receive(:create_tags_for_vm)
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

      it 'calls method to tag vm' do
        expect(tags_mng).to have_received(:create_tags_for_vm).with(vm)
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

      it 'does not tag vm' do
        expect(tags_mng).not_to receive(:create_tags_for_vm)
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

        name: 'name',
        id: 1,

        virtual_machines: double(create: vm)
      )
    end
    let(:tags_mng) { double('tags manager') }
    let(:tags_manager_class) { double('tags manager class', new: tags_mng) }
    let(:updater) { double('updater', update: true) }
    let(:updater_class) { double('updater class', new: updater) }

    let(:vm_creator) { double('vm creator', :spawn_vm! => 'server_id') }
    let(:vm_creator_class) { double('vm creator class') }

    let(:tmpl)   { double('tmpl', compute_site: 'cs') }
    let(:flavor) { 'flavor' }
    let(:name)   { 'name' }
    let(:vm)     { double('vm', errors: { to_json: {} }) }

    subject { ApplianceVmsManager.new(appl, updater_class, vm_creator_class, tags_manager_class) }

    before do
      allow(vm_creator_class).to receive(:new).with(tmpl,
        {flavor: flavor, name: name, user_data: 'user data', user_key: 'user key'})
          .and_return(vm_creator)
      allow(tags_mng).to receive(:create_tags_for_vm)
    end

    context 'when user can afford to spawn VM with selected flavor' do
      before do
        allow(BillingService).to receive(:can_afford_flavor?)
          .with(appl, flavor).and_return(true)
      end

      it 'creates new VM' do
        allow(vm).to receive(:valid?).and_return(true)
        expect(appl.virtual_machines).to receive(:create) do |params|
          expect(params[:name]).to eq name
          expect(params[:source_template]).to eq tmpl
          expect(params[:virtual_machine_flavor]).to eq flavor
          expect(params[:managed_by_atmosphere]).to be_truthy
          expect(params[:id_at_site]).to eq 'server_id'
          expect(params[:compute_site]).to eq tmpl.compute_site
        end.and_return(vm)

        subject.spawn_vm!(tmpl, flavor, name)
      end

      it 'sets state to satisfied' do
        allow(vm).to receive(:valid?).and_return(true)
        expect(appl).to receive(:state=).with(:satisfied)

        subject.spawn_vm!(tmpl, flavor, name)
      end

      it 'calls method to tag vm' do
        allow(vm).to receive(:valid?).and_return(true)
        subject.spawn_vm!(tmpl, flavor, name)
        expect(tags_mng).to have_received(:create_tags_for_vm)
      end

      it 'updates appliance services with new VM hint' do
        allow(vm).to receive(:valid?).and_return(true)
        expect(updater).to receive(:update).with({ new_vm: vm })

        subject.spawn_vm!(tmpl, flavor, name)
      end

      it 'sets state to unsatisfied when VM cannot be assigned to appliance' do
        allow(vm).to receive(:valid?).and_return(false)
        expect(appl).to receive(:state=).with(:unsatisfied)

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