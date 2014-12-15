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

  let!(:user_fund) { create(:user_fund) }

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

end
