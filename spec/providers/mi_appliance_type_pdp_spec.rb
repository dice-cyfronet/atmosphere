require 'spec_helper'

describe MiApplianceTypePdp do
  let(:resource_access) { double('mi resource access') }
  let(:resource_access_class) { double }
  let(:ticket) { 'ticket' }

  before do
    allow(resource_access_class).to receive(:new)
      .with('AtomicService', {ticket: ticket}).and_return(resource_access)
  end

  subject { MiApplianceTypePdp.new(ticket, resource_access_class) }

  context 'with single resource' do
    let(:at) { build(:appliance_type, id: 1) }

    context '#can_start?' do
      it 'allows to start when user has reader role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :reader).and_return(true)

        expect(subject.can_start?(at)).to be_true
      end

      it 'does not allow when user does not have reader role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :reader).and_return(false)

        expect(subject.can_start?(at)).to be_false
      end
    end

    context '#can_edit?' do
      it 'allows to start when user has editor role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :editor).and_return(true)

        expect(subject.can_edit?(at)).to be_true
      end

      it 'does not allow when user does not have editor role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :editor).and_return(false)

        expect(subject.can_edit?(at)).to be_false
      end
    end

    context '#can_manage?' do
      it 'allows to start when user has manager role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :manager).and_return(true)

        expect(subject.can_manage?(at)).to be_true
      end

      it 'does not allow when user does not have manager role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :manager).and_return(false)

        expect(subject.can_manage?(at)).to be_false
      end
    end
  end

  context 'with resources list' do
    let!(:at1) { create(:appliance_type) }
    let!(:at2) { create(:appliance_type) }
    let!(:at3) { create(:appliance_type) }

    it 'filter available appliance types for the user' do
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:reader).and_return([at1.id, at3.id])

      filtered_ats = subject.filter(ApplianceType.all)

      expect(filtered_ats.size).to eq 2
      expect(filtered_ats).to include at1
      expect(filtered_ats).to include at3
    end
  end
end