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

    context '#can_start_in_production?' do
      it 'allows to start when user has reader role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :reader).and_return(true)

        expect(subject.can_start_in_production?(at)).to be_true
      end

      it 'allows to start when user has manager role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :reader).and_return(false)
        allow(resource_access).to receive(:has_role?)
          .with(1, :manager).and_return(true)

        expect(subject.can_start_in_production?(at)).to be_true
      end

      it 'does not allow to start when user does not have reader and editor role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :reader).and_return(false)
        allow(resource_access).to receive(:has_role?)
          .with(1, :manager).and_return(false)

        expect(subject.can_start_in_production?(at)).to be_false
      end

      it 'does not allow to start when at visible_to is eq developer' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :reader).and_return(true)
        at.visible_to = :developer

        expect(subject.can_start_in_production?(at)).to be_false
      end
    end

    context '#can_start_in_development?' do
      it 'allows to start when user has editor role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :editor).and_return(true)

        expect(subject.can_start_in_development?(at)).to be_true
      end

      it 'allows to start when user has manager role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :editor).and_return(false)
        allow(resource_access).to receive(:has_role?)
          .with(1, :manager).and_return(true)

        expect(subject.can_start_in_development?(at)).to be_true
      end

      it 'does not allow when user does not have editor and manager roles' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :editor).and_return(false)
        allow(resource_access).to receive(:has_role?)
          .with(1, :manager).and_return(false)

        expect(subject.can_start_in_development?(at)).to be_false
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
    let!(:at1) { create(:appliance_type, visible_to: :all) }
    let!(:at2) { create(:appliance_type) }
    let!(:at3) { create(:appliance_type, visible_to: :all) }
    let!(:at4) { create(:appliance_type, visible_to: :developer) }

    before do
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:reader).and_return([at1.id])
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:editor).and_return([at2.id])
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:manager).and_return([at3.id, at4.id])
    end

    it 'filter all available appliance' do
      filtered_ats = subject.filter(ApplianceType.all)

      expect(filtered_ats.size).to eq 4
      expect(filtered_ats).to include at1
      expect(filtered_ats).to include at2
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at4
    end

    it 'filter available appliance types for production' do
      filtered_ats = subject.filter(ApplianceType.all, :production)

      expect(filtered_ats.size).to eq 2
      expect(filtered_ats).to include at1
      expect(filtered_ats).to include at3
    end

    it 'filter available appliance types for development' do
      filtered_ats = subject.filter(ApplianceType.all, :development)

      expect(filtered_ats.size).to eq 3
      expect(filtered_ats).to include at2
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at4
    end

    it 'filter available appliance types for manager' do
      filtered_ats = subject.filter(ApplianceType.all, :manager)

      expect(filtered_ats.size).to eq 2
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at4
    end
  end
end