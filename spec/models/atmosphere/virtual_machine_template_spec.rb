# == Schema Information
#
# Table name: virtual_machine_templates
#
#  id                    :integer          not null, primary key
#  id_at_site            :string(255)      not null
#  name                  :string(255)      not null
#  state                 :string(255)      not null
#  managed_by_atmosphere :boolean          default(FALSE), not null
#  compute_site_id       :integer          not null
#  virtual_machine_id    :integer
#  appliance_type_id     :integer
#  created_at            :datetime
#  updated_at            :datetime
#  architecture          :string(255)      default("x86_64")
#

require 'rails_helper'
require 'securerandom'
require_relative "../../shared_examples/childhoodable.rb"

describe Atmosphere::VirtualMachineTemplate do

  before do
    Fog.mock!
  end

  it { should validate_inclusion_of(:state).in_array(%w(active deleted error saving queued killed pending_delete)) }

  context 'name sanitization' do
    it 'appends underscores to name that is too short' do
      expect(Atmosphere::VirtualMachineTemplate.sanitize_tmpl_name('s')).to eq 's__'
    end

    it 'trims too long name to 128 characters' do
      expect(Atmosphere::VirtualMachineTemplate.sanitize_tmpl_name(SecureRandom.hex(65)).length).to eq 128
    end

    it 'replaces illegal characters with underscore' do
      expect(Atmosphere::VirtualMachineTemplate.sanitize_tmpl_name('!@#$%^&* ')).to eq '_________'
    end
  end

  context 'architecture validation' do
    it "adds 'invalid architexture' error message" do
      vmt = build(:virtual_machine_template, architecture: 'invalid architecture')
      saved = vmt.save
      expect(saved).to be false
      expect(vmt.errors.messages).to eq({architecture: ['is not included in the list']})
    end
  end

  context 'state is updated' do
    let!(:vm) { create(:virtual_machine, managed_by_atmosphere: true) }
    subject { create(:virtual_machine_template, source_vm: vm, state: :saving) }
    let(:active_vmt) { create(:virtual_machine_template, source_vm: vm, state: :active) }
    let(:at) { create(:appliance_type) }
    let(:assigned_vmt) { create(:virtual_machine_template, source_vm: vm, appliance_type: at) }
    let(:cc_mock) { double('cloud client mock') }
    let(:servers_mock) { double('servers') }
    before do
      allow(Atmosphere).to receive(:get_cloud_client).and_return(cc_mock)
      allow(cc_mock).to receive(:servers).and_return(servers_mock)
    end

    context 'active' do
      it 'sets source vm to nil' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :active)
        expect(subject.source_vm).to be_nil
      end

      it 'destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :active) }.to change { Atmosphere::VirtualMachine.count}.by(-1)
      end

      it 'destroys vm in cloud if it does not have an appliance associated' do
        expect(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :active)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect(servers_mock).to_not receive(:destroy)
        subject.update_attribute(:state, :active)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect { subject.update_attribute(:state, :active) }.to_not change { Atmosphere::VirtualMachine.count }
      end

      it 'shows up on the active scope' do
        expect(Atmosphere::VirtualMachineTemplate.active).to_not include subject
        expect(Atmosphere::VirtualMachineTemplate.active).to include active_vmt
      end

      it 'shows up on the unassigned scope' do
        expect(Atmosphere::VirtualMachineTemplate.unassigned).to_not include assigned_vmt
        expect(Atmosphere::VirtualMachineTemplate.unassigned).to include active_vmt
      end
    end

    context 'error' do
      it 'sets source vm to nil' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :error)
        expect(subject.source_vm).to be_nil
      end

      it 'destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :error) }.to change { Atmosphere::VirtualMachine.count}.by(-1)
      end

      it 'destroys vm in cloud if it does not have an appliance associated' do
        expect(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :error)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect(servers_mock).to_not receive(:destroy)
        subject.update_attribute(:state, :error)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect { subject.update_attribute(:state, :error) }.to_not change { Atmosphere::VirtualMachine.count }
      end
    end

    context 'saving' do
      it 'does not set source vm to nil' do
        subject.update_attribute(:state, :saving)
        expect(subject.source_vm).to eq vm
      end

      it 'does not destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :saving) }.to_not change { Atmosphere::VirtualMachine.count}
      end

      it 'does not destroy vm in cloud if it does not have an appliance associated' do
        expect(servers_mock).to_not receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :saving)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect(servers_mock).to_not receive(:destroy)
        subject.update_attribute(:state, :saving)
      end

      it 'does not destroy vm in cloud if it has an appliance associated' do
        create(:appliance, virtual_machines: [vm])
        expect { subject.update_attribute(:state, :saving) }.to_not change { Atmosphere::VirtualMachine.count }
      end
    end
  end

  describe '#destroy' do
    let(:images) { double(:images) }
    let(:cloud_client) { double(:cloud_client, images: images) }

    before do
      allow(t).to receive(:cloud_client).and_return(cloud_client)
    end

    context 'when template is managed by atmosphere' do
      let(:t) { build(:tenant) }
      let(:tmp) do
        build(:virtual_machine_template,
              managed_by_atmosphere: true,
              tenants: [t])
      end

      it 'removes template from tenant' do
        expect(images).to receive(:destroy).with(tmp.id_at_site)
        tmp.destroy
      end

      it 'ignores when VM does not exist on OpenStack' do
        delete_with_success_when_exception(Fog::Compute::OpenStack::NotFound)
      end

      it 'ignores when VM does not exist on Amazon' do
        delete_with_success_when_exception(Fog::Compute::AWS::NotFound)
      end

      def delete_with_success_when_exception(e)
        tmpl = create(:virtual_machine_template,
                      managed_by_atmosphere: true)

        allow(tmpl).
          to receive(:cloud_client).
          and_return(cloud_client)

        allow(images).
          to receive(:destroy).
          with(tmpl.id_at_site).
          and_raise(e)

        expect { tmpl.destroy }.
          to change { Atmosphere::VirtualMachineTemplate.count }.by(-1)
      end
    end

    context 'when template is not managed by atmosphere' do
      let(:t) { build(:tenant) }
      let(:external_tmp) { build(:virtual_machine_template, tenants: [t]) }

      it 'removes template from compute site' do
        expect(images).to_not receive(:destroy)

        external_tmp.destroy

        expect(external_tmp.errors).not_to be_empty
      end
    end

    context 'when tpl is in saving state' do
      let(:t) { create(:tenant) }
      let(:vm) { create(:virtual_machine, managed_by_atmosphere: true) }
      let!(:tpl_in_saving_state) { create(:virtual_machine_template, source_vm: vm, state: :saving, tenants: [t]) }

      context 'and source VM is assigned to appliance' do
        before { create(:appliance, virtual_machines: [vm]) }

        it 'does not remove source VM' do
          expect {
            tpl_in_saving_state.destroy
          }.to change { Atmosphere::VirtualMachine.count }.by(0)
        end
      end

      context 'and source VM is not assigned to any appliance' do
        it 'removes source VM' do
          expect {
            tpl_in_saving_state.destroy
          }.to change { Atmosphere::VirtualMachine.count }.by(-1)
        end
      end
    end
  end

  describe '::create_from_vm' do
    let(:t) { create(:tenant) }
    let(:cloud_client) { double(:cloud_client) }
    let(:vm) { create(:virtual_machine, id_at_site: 'id', tenant: t) }
    let(:vm2) { create(:virtual_machine, name: vm.name, id_at_site: 'id2', tenant: t) }

    before do
      allow(cloud_client).to receive(:save_template).and_return(SecureRandom.hex(5))
      allow(t).to receive(:cloud_client).and_return(cloud_client)
    end

    it 'sets managed_by_atmosphere to true' do
      tmpl = Atmosphere::VirtualMachineTemplate.create_from_vm(vm)

      expect(tmpl.managed_by_atmosphere).to be_truthy
    end

    it 'sets VM state to "saving"' do
      tmpl = Atmosphere::VirtualMachineTemplate.create_from_vm(vm)
      vm.reload

      expect(vm.state).to eq 'saving'
    end

    it 'saves template from machines with identical names' do
      tmpl1 = Atmosphere::VirtualMachineTemplate.create_from_vm(vm)
      tmpl2 = Atmosphere::VirtualMachineTemplate.create_from_vm(vm2)

      expect(vm.name).to eq(vm2.name)
      expect(tmpl1.name).not_to eq(tmpl2.name)
    end
  end

  it_behaves_like 'childhoodable'

  describe '::version' do
    it 'set version to 1 for first appliance type VMT' do
      at = create(:appliance_type)
      vmt = create(:virtual_machine_template, appliance_type: at)

      expect(vmt.version).to eq 1
    end

    it 'increment version for new added VMT' do
      at = create(:appliance_type)
      create(:virtual_machine_template, appliance_type: at)
      vmt = create(:virtual_machine_template, appliance_type: at)

      expect(vmt.version).to eq 2
    end

    it 'does not set version when it is already set' do
      at = create(:appliance_type)
      vmt = create(:virtual_machine_template,
                   appliance_type: at,
                   version: 15)

      expect(vmt.version).to eq 15
    end

    it 'set version when assigment to AT changes' do
      vmt = create(:virtual_machine_template, version: 15)
      at = create(:appliance_type)

      vmt.appliance_type = at
      vmt.save

      expect(vmt.version).to eq 1
    end

    it 'setting version has precedence over assigning to AT' do
      vmt = create(:virtual_machine_template, version: 15)
      at = create(:appliance_type)

      vmt.appliance_type = at
      vmt.version = 3
      vmt.save

      expect(vmt.version).to eq 3
    end
  end
end
