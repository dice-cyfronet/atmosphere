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
#

require 'spec_helper'
require 'securerandom'

describe VirtualMachineTemplate do

  before do
    Fog.mock!
  end

  expect_it { to ensure_inclusion_of(:state).in_array(%w(active deleted error saving queued killed pending_delete)) }

  context 'name sanitization' do
    it 'appends underscores to name that is too short' do
      expect(VirtualMachineTemplate.sanitize_tmpl_name('s')).to eq 's__'
    end
    
    it 'trims too long name to 128 characters' do
      expect(VirtualMachineTemplate.sanitize_tmpl_name(SecureRandom.hex(65)).length).to eq 128
    end

    it 'replaces illegal characters with underscore' do
      expect(VirtualMachineTemplate.sanitize_tmpl_name('!@#$%^&* ')).to eq '_________'
    end
  end

  context 'name validation' do

    INVALID_NAME_MSG = "can contain letters, numbers, '(', ')', '.', '-', '/' and '_' and must be between 3 and 128 characters long."

    it "adds 'invalid' message if name is too short" do
      vmt = VirtualMachineTemplate.new(name:'sh', id_at_site: 'ID-AT-SITE', state: :active, compute_site: create(:compute_site))
      saved = vmt.save
      expect(saved).to be false
      expect(vmt.errors.messages).to eq({:name => [INVALID_NAME_MSG]})
    end
    it "adds 'invalid' message if name is too long" do
      too_long_name = SecureRandom.hex(65) # given a 130 characters long random string
      vmt = VirtualMachineTemplate.new(name:too_long_name, id_at_site: 'ID-AT-SITE', state: :active, compute_site: create(:compute_site))
      saved = vmt.save
      expect(saved).to be false
      expect(vmt.errors.messages).to eq({:name => [INVALID_NAME_MSG]})
    end
    it "adds 'invalid' message if name contatins illegal characters" do
      invalid_name = 'i am so invalid!'
      vmt = VirtualMachineTemplate.new(name:invalid_name, id_at_site: 'ID-AT-SITE', state: :active, compute_site: create(:compute_site))
      saved = vmt.save
      expect(saved).to be false
      expected_msg = 'Name must be between 3 and 128 characters long.'
      expect(vmt.errors.messages).to eq({:name => [INVALID_NAME_MSG]})
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
      Air.stub(:get_cloud_client).and_return(cc_mock)
      cc_mock.stub(:servers).and_return(servers_mock)
    end

    context 'active' do
      it 'sets source vm to nil' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        subject.update_attribute(:state, :active)
        expect(subject.source_vm).to be_nil
      end

      it 'destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :active) }.to change { VirtualMachine.count}.by(-1)
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
        expect { subject.update_attribute(:state, :active) }.to_not change { VirtualMachine.count }
      end

      it 'shows up on the active scope' do
        expect(VirtualMachineTemplate.active).to_not include subject
        expect(VirtualMachineTemplate.active).to include active_vmt
      end

      it 'shows up on the unassigned scope' do
        expect(VirtualMachineTemplate.unassigned).to_not include assigned_vmt
        expect(VirtualMachineTemplate.unassigned).to include active_vmt
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
        expect { subject.update_attribute(:state, :error) }.to change { VirtualMachine.count}.by(-1)
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
        expect { subject.update_attribute(:state, :error) }.to_not change { VirtualMachine.count }
      end
    end

    context 'saving' do
      it 'does not set source vm to nil' do
        subject.update_attribute(:state, :saving)
        expect(subject.source_vm).to eq vm
      end

      it 'does not destroys vm in DB if it does not have an appliance associated' do
        allow(servers_mock).to receive(:destroy).with(vm.id_at_site)
        expect { subject.update_attribute(:state, :saving) }.to_not change { VirtualMachine.count}
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
        expect { subject.update_attribute(:state, :saving) }.to_not change { VirtualMachine.count }
      end
    end
  end

  describe '#destroy' do
    let(:images) { double(:images) }
    let(:cloud_client) { double(:cloud_client, images: images) }

    before do
      ComputeSite.any_instance.stub(:cloud_client).and_return(cloud_client)
    end

    context 'when template is managed by atmosphere' do
      let(:tmp) { build(:virtual_machine_template, managed_by_atmosphere: true) }

      it 'removes template from compute site' do
        expect(images).to receive(:destroy).with(tmp.id_at_site)
        tmp.destroy
      end
    end

    context 'when template is not managed by atmosphere' do
      let(:external_tmp) { build(:virtual_machine_template) }

      it 'removes template from compute site' do
        expect(images).to_not receive(:destroy)

        external_tmp.destroy

        expect(external_tmp.errors).not_to be_empty
      end
    end

    context 'when tpl is in saving state' do
      let(:vm) { create(:virtual_machine) }
      let!(:tpl_in_saving_state) { create(:virtual_machine_template, source_vm: vm, state: :saving) }

      context 'and source VM is assigned to appliance' do
        before { create(:appliance, virtual_machines: [vm]) }

        it 'does not remove source VM' do
          expect {
            tpl_in_saving_state.destroy
          }.to change { VirtualMachine.count }.by(0)
        end
      end

      context 'and source VM is not assigned to any appliance' do
        it 'removes source VM' do
          expect {
            tpl_in_saving_state.destroy
          }.to change { VirtualMachine.count }.by(-1)
        end
      end
    end
  end

  describe '::create_from_vm' do
    let(:cloud_client) { double(:cloud_client) }
    let(:vm) { create(:virtual_machine, id_at_site: 'id') }

    before do
      allow(cloud_client).to receive(:save_template).and_return(SecureRandom.hex(5))
      ComputeSite.any_instance.stub(:cloud_client).and_return(cloud_client)
    end

    it 'sets managed_by_atmosphere to true' do
      tmpl = VirtualMachineTemplate.create_from_vm(vm)

      expect(tmpl.managed_by_atmosphere).to be_true
    end

    it 'sets VM state to "saving"' do
      tmpl = VirtualMachineTemplate.create_from_vm(vm)
      vm.reload

      expect(vm.state).to eq 'saving'
    end
  end
end
