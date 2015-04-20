# == Schema Information
#
# Table name: user_funds
#
#  id      :integer          not null, primary key
#  user_id :integer
#  fund_id :integer
#  default :boolean          default(FALSE)
#

require 'rails_helper'

describe Atmosphere::UserFund do
  it { should validate_uniqueness_of(:user_id).
                  scoped_to(:fund_id).
                  with_message(I18n.t('funds.unique_user'))
  }

  let!(:user_fund) { create(:user_fund, user: create(:poor_chap)) }

  it 'is valid' do
    expect(user_fund).to be_valid
  end

  it 'prevents duplication of user assignment to a fund' do
    uf = Atmosphere::UserFund.create(
      user: user_fund.user,
      fund: user_fund.fund
    )
    expect(uf).not_to be_valid
    expect(uf.errors.full_messages.first).
      to include(I18n.t('funds.unique_user'))
  end


  describe '#ensure_single_default' do
    it 'makes first user_fund default' do
      expect(user_fund.default).to be_truthy
    end

    it 'blocks setting the only fund as not default' do
      expect(user_fund.default).to be_truthy
      user_fund.default = false
      user_fund.save
      expect(user_fund.reload.default).to be_truthy
    end

    it 'does not bother single default fund creation' do
      pc = create(:poor_chap)
      uf = create(:user_fund, user: pc, default: true)
      expect(uf.reload.default).to be_truthy
    end

    it 'keeps only single default user fund' do
      uf = create(:user_fund, user: user_fund.user, default: true)
      expect(Atmosphere::UserFund.count).to eq 2
      expect(uf.reload.default).to be_truthy
      expect(user_fund.reload.default).to be_falsey
    end

    it 'does not prematurely default to an invalid fund' do
      expect do
        uf = build(:user_fund,
                   fund: user_fund.fund,
                   user: user_fund.user,
                   default: true)
        uf.save
      end.to change { Atmosphere::UserFund.count }.by 0

      expect(user_fund.reload.default).to be_truthy
    end
  end

  describe '#reallocate_default' do
    it 'does nothing when last fund is removed' do
      user_fund.destroy
      expect(Atmosphere::UserFund.count).to eq 0
    end

    it 'reallocates removed default' do
      uf = create(:user_fund, user: user_fund.user)
      uf2 = create(:user_fund, user: user_fund.user)
      expect(user_fund.reload.default).to be_truthy
      expect(uf.reload.default).to be_falsey
      expect(uf2.reload.default).to be_falsey
      user_fund.destroy
      expect([uf.reload.default, uf2.reload.default]).
        to contain_exactly true, false
    end

    it 'does nothing when removing non-default fund' do
      uf = create(:user_fund, user: user_fund.user)
      uf2 = create(:user_fund, user: user_fund.user)
      expect(user_fund.reload.default).to be_truthy
      expect(uf.reload.default).to be_falsey
      expect(uf2.reload.default).to be_falsey
      uf.destroy
      expect(user_fund.reload.default).to be_truthy
      expect(uf2.reload.default).to be_falsey
    end
  end
end
