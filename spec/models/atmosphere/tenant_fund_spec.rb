require 'spec_helper'
require 'rails_helper'

describe Atmosphere::TenantFund do

  it { should validate_uniqueness_of(:tenant_id).
                scoped_to(:fund_id).
                with_message(I18n.t('funds.unique_compute_site'))
  }

  let!(:tenant_fund) { create(:tenant_fund) }

  it 'is valid' do
    expect(tenant_fund).to be_valid
  end

  it 'prevents duplication of tenant assignment to a fund' do
    tf = Atmosphere::TenantFund.create(
        tenant: tenant_fund.tenant,
        fund: tenant_fund.fund
    )
    expect(tf).not_to be_valid
    expect(tf.errors.full_messages.first).
        to include(I18n.t('funds.unique_compute_site'))
  end

end
