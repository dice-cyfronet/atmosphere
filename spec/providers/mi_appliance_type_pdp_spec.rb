require 'spec_helper'

describe MiApplianceTypePdp do
  let(:resource_access) { double('mi resource access') }
  let(:resource_access_class) { double }
  let(:ticket) { 'ticket' }
  let(:current_user) { build(:user, mi_ticket: ticket) }

  before do
    allow(Air.config.vph).to receive(:host).and_return('https://mi.host')
    allow(Air.config.vph).to receive(:ssl_verify).and_return(false)

    allow(resource_access_class).to receive(:new)
      .with(
        'AtomicService', {
          ticket: ticket,
          verify: false,
          url: 'https://mi.host',
      }).and_return(resource_access)
  end

  subject { MiApplianceTypePdp.new(current_user, resource_access_class) }

  context 'with single resource' do
    let(:at) { build(:appliance_type, id: 1) }

    context '#can_start_in_production?' do
      it 'allows to start when user has reader role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Reader).and_return(true)

        expect(subject.can_start_in_production?(at)).to be_true
      end

      it 'does not allow to start when user does not have reader and editor role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Reader).and_return(false)

        expect(subject.can_start_in_production?(at)).to be_false
      end

      it 'does not allow to start when at visible_to is eq developer' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Reader).and_return(true)
        at.visible_to = :developer

        expect(subject.can_start_in_production?(at)).to be_false
      end

      it 'allow to start AT when admin' do
        current_user_is_admin

        expect(subject.can_start_in_production?(at)).to be_true
      end
    end

    context '#can_start_in_development?' do
      it 'allows to start when user has editor role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Editor).and_return(true)

        expect(subject.can_start_in_development?(at)).to be_true
      end

      it 'does not allow when user does not have editor and manager roles' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Editor).and_return(false)

        expect(subject.can_start_in_development?(at)).to be_false
      end

      it 'allow to start AT when admin' do
        current_user_is_admin

        expect(subject.can_start_in_development?(at)).to be_true
      end
    end

    context '#can_manage?' do
      it 'allows to start when user has manager role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Manager).and_return(true)

        expect(subject.can_manage?(at)).to be_true
      end

      it 'does not allow when user does not have manager role' do
        allow(resource_access).to receive(:has_role?)
          .with(1, :Manager).and_return(false)

        expect(subject.can_manage?(at)).to be_false
      end

      it 'allow to start AT when admin' do
        current_user_is_admin

        expect(subject.can_manage?(at)).to be_true
      end

      it 'allow to start when user is AT author' do
        at = build(:appliance_type, author: current_user, visible_to: :owner)

        expect(subject.can_manage?(at)).to be_true
      end
    end
  end

  let!(:at1) { create(:appliance_type, visible_to: :all) }
  let!(:at2) { create(:appliance_type, visible_to: :owner) }
  let!(:at3) { create(:appliance_type, visible_to: :all) }
  let!(:at4) do
    create(:appliance_type,
      visible_to: :developer,
      author: current_user
    )
  end
  let!(:at5) { create(:appliance_type, visible_to: :owner, author: current_user) }

  context 'when normal user' do
    before do
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:Reader).and_return([at1.id, at2.id, at3.id, at4.id])
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:Editor).and_return([at2.id, at3.id, at4.id])
      allow(resource_access).to receive(:availabe_resource_ids)
        .with(:Manager).and_return([at3.id, at4.id])
    end

    it 'filter all available appliance' do
      filtered_ats = subject.filter(ApplianceType.all)

      expect(filtered_ats.size).to eq 5
      expect(filtered_ats).to include at1
      expect(filtered_ats).to include at2
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at4
      expect(filtered_ats).to include at5
    end

    it 'filter available appliance types for production' do
      filtered_ats = subject.filter(ApplianceType.all, :production)

      expect(filtered_ats.size).to eq 4
      expect(filtered_ats).to include at1
      expect(filtered_ats).to include at2
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at5
    end

    it 'filter available appliance types for development' do
      filtered_ats = subject.filter(ApplianceType.all, :development)

      expect(filtered_ats.size).to eq 4
      expect(filtered_ats).to include at2
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at4
      expect(filtered_ats).to include at5
    end

    it 'filter available appliance types for manager' do
      filtered_ats = subject.filter(ApplianceType.all, :manage)

      expect(filtered_ats.size).to eq 3
      expect(filtered_ats).to include at3
      expect(filtered_ats).to include at4
      expect(filtered_ats).to include at5
    end

    it 'returns all resources when user is an admin' do
      current_user_is_admin

      filtered_ats = subject.filter(ApplianceType.all, :manage)

      expect(filtered_ats.size).to eq 5
    end
  end

  def current_user_is_admin
    allow(Air.config).to receive(:skip_pdp_for_admin).and_return(true)
    allow(current_user).to receive(:has_role?).with(:admin).and_return(true)
  end
end