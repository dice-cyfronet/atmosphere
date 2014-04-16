require 'spec_helper'

describe DefaultPdp do
  context '#can_manage?' do
    let(:user) { build(:user, id: 1) }
    subject { DefaultPdp.new(user) }

    it 'allows to manage owned appliance types' do
      at = build(:appliance_type, user_id: user.id)

      expect(subject.can_manage?(at)).to be_true
    end

    it 'does not allow to manage not owned appliance types' do
      at = build(:appliance_type)

      expect(subject.can_manage?(at)).to be_false
    end
  end

  context '#filter' do
    let(:user)  { create(:user) }
    let!(:a1)   { create(:appliance_type, visible_to: :all) }
    let!(:a2)   { create(:appliance_type, visible_to: :developer, author: user) }
    let!(:a3)   { create(:appliance_type, visible_to: :owner, author: user) }

    subject { DefaultPdp.new(user) }

    it 'returns all, owner ATs for production mode' do
      filtered = subject.filter(ApplianceType.all, 'production')

      expect(filtered.count).to eq 2
      expect(filtered).to include a1
      expect(filtered).to include a3
    end

    it 'returns owned ATs for manage mode' do
      filtered = subject.filter(ApplianceType.all, 'manage')

      expect(filtered.count).to eq 2

      expect(filtered).to include a2
      expect(filtered).to include a3
    end

    it 'returns all, developer and owned ATs for development mode' do
      filtered = subject.filter(ApplianceType.all, 'development')

      expect(filtered.count).to eq 3
    end
  end
end