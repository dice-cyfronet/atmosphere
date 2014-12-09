require 'spec_helper'
require 'rails_helper'

describe Atmosphere::ComputeSiteFund do

  it { should validate_uniqueness_of(:compute_site_id).
                scoped_to(:fund_id).
                with_message(I18n.t('funds.unique_compute_site'))
  }

  let!(:compute_site_fund) { create(:compute_site_fund) }

  it 'is valid' do
    expect(compute_site_fund).to be_valid
  end

  it 'prevents duplication of compute site assignment to a fund' do
    csf = Atmosphere::ComputeSiteFund.create(
        compute_site: compute_site_fund.compute_site,
        fund: compute_site_fund.fund
    )
    expect(csf).not_to be_valid
    expect(csf.errors.full_messages.first).
        to include(I18n.t('funds.unique_compute_site'))
  end

end
