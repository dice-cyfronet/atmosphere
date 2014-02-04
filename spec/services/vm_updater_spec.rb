require 'spec_helper'

describe VmUpdater do
  let(:cs)  { create(:compute_site) }
  let(:vmt) { create(:virtual_machine_template, compute_site: cs) }

  before do
    VirtualMachineTemplate.stub(:find_by).with(compute_site: cs, id_at_site: "vmt_id_at_site").and_return(vmt)
  end

  describe 'VM states' do
    context "when task state equals to image_snapshot" do
      let(:server) do
        double(
          id: 'id_at_site',
          image_id: 'vmt_id_at_site',
          name: 'name',
          state: 'active',
          task_state: 'image_snapshot',
          public_ip_address: nil,
          addresses: nil
        )
      end

      subject { VmUpdater.new(cs, server) }

      it 'sets "saving" state' do
        vm = subject.update
        expect(vm.state).to eq 'saving'
      end
    end

    context 'when relation to saved_templates is not empty' do
      let(:server) do
        double(
          id: 'id_at_site',
          image_id: 'vmt_id_at_site',
          name: 'name',
          state: 'active',
          task_state: nil,
          public_ip_address: nil,
          addresses: nil
        )
      end

      before do
        vm = create(:virtual_machine, id_at_site: 'id_at_site', saved_templates: [vmt], compute_site: cs)
        vm.saved_templates << vmt
      end

      subject { VmUpdater.new(cs, server) }

      it 'sets "saving" state' do
        vm = subject.update
        expect(vm.state).to eq 'saving'
      end
    end
  end
end