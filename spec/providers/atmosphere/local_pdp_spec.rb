require 'rails_helper'

describe Atmosphere::LocalPdp do
  context '#can_manage?' do
    let(:user) { create(:user) }
    subject { Atmosphere::LocalPdp.new(user) }

    it 'allows to manage owned appliance types' do
      at = build(:appliance_type, user_id: user.id)

      expect(subject.can_manage?(at)).to be_truthy
    end

    it 'allows to manage appliance types where management permissions have been granted' do
      at = build(:appliance_type)
      create(:user_appliance_type, user: user, appliance_type: at, role: 'manager')

      expect(subject.can_manage?(at)).to be_truthy
    end

    it 'does not allow to manage unowned appliance types' do
      at = build(:appliance_type)

      expect(subject.can_manage?(at)).to be_falsy
    end
  end

  context '#can_start_in_development?' do
    let(:user) { create(:user) }
    let(:at) { build(:appliance_type) }

    subject { Atmosphere::LocalPdp.new(user) }

    it 'allows starting managed services in development' do
      create(:user_appliance_type, user: user, appliance_type: at, role: 'manager')

      expect(subject.can_start_in_development?(at)).to be_truthy
    end

    it 'allows starting developer-access services in development' do
      create(:user_appliance_type, user: user, appliance_type: at, role: 'developer')

      expect(subject.can_start_in_development?(at)).to be_truthy
    end

    it 'disallows starting production-access services in development' do
      create(:user_appliance_type, user: user, appliance_type: at, role: 'reader')

      expect(subject.can_start_in_development?(at)).to be_falsy
    end
  end

  context '#can_start_in_production?' do
    let(:user) { create(:user) }
    let(:at) { build(:appliance_type) }
    subject { Atmosphere::LocalPdp.new(user) }

    it 'allows starting managed services in production' do
      create(:user_appliance_type, user: user, appliance_type: at, role: 'manager')

      expect(subject.can_start_in_production?(at)).to be_truthy
    end

    it 'allows starting developer-access services in production' do
      create(:user_appliance_type, user: user, appliance_type: at, role: 'developer')

      expect(subject.can_start_in_production?(at)).to be_truthy
    end

    it 'allows starting production-access services in production' do
      create(:user_appliance_type, user: user, appliance_type: at, role: 'reader')

      expect(subject.can_start_in_production?(at)).to be_truthy
    end
  end

  context 'unknown or unassigned role' do
    let(:user) { build(:user, id: 1) }
    let(:at) { build(:appliance_type) }
    subject { Atmosphere::LocalPdp.new(user) }

    it 'disallows access when no role is defined and user is not owner' do
      expect(subject.can_manage?(at)).to be_falsy
      expect(subject.can_start_in_development?(at)).to be_falsy
      expect(subject.can_start_in_production?(at)).to be_falsy
    end
  end

  context 'filters' do
    let(:u1) { create(:user) }
    let(:at1) { create(:appliance_type) }
    let(:at2) { create(:appliance_type) }
    subject { Atmosphere::LocalPdp.new(u1) }

    it 'returns services which the user can manage' do
      create(:user_appliance_type, user: u1, appliance_type: at2, role: 'manager')
      expect(subject.filter(Atmosphere::ApplianceType.all, 'manage')).to eq [at2]
    end

    it 'returns services which the user can start in production' do
      create(:user_appliance_type, user: u1, appliance_type: at2, role: 'manager')
      ats = subject.filter(Atmosphere::ApplianceType.all, 'production')
      expect(ats.length).to eq 1
      expect(ats).to include at2
      create(:user_appliance_type, user: u1, appliance_type: at1, role: 'reader')
      ats = subject.filter(Atmosphere::ApplianceType.all, 'production')
      expect(ats.length).to eq 2
      expect(ats).to include at1
    end
  end
end