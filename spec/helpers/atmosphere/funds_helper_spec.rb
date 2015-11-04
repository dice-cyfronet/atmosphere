require 'rails_helper'

describe Atmosphere::FundsHelper, type: :helper do

  describe '#fund_balance_full_precision' do

    it 'properly format positive number lower than 10000' do
      expect(fund_balance_full_precision(345)).to eq '0.0345'
    end

    it 'properly format number higher than 10000' do
      expect(fund_balance_full_precision(22345)).to eq '2.2345'
    end

    it 'properly format negative number higher than -10000' do
      expect(fund_balance_full_precision(-345)).to eq '-0.0345'
    end

    it 'properly format number lower than -10000' do
      expect(fund_balance_full_precision(-22345)).to eq '-2.2345'
    end

    it 'deal with strings as well' do
      expect(fund_balance_full_precision('-22345')).to eq '-2.2345'
    end

    it 'floor floats since it works only for integers' do
      expect(fund_balance_full_precision(37.233)).to eq '0.0037'
      expect(fund_balance_full_precision(37.87)).to eq '0.0037'
    end

  end

  describe '#last_months_names' do

    it 'returns last 12 months' do
      expect(last_months_names.last).
        to eq Date::MONTHNAMES[Time.zone.now.month]
      expect(last_months_names.first).
        to eq Date::MONTHNAMES[(Time.zone.now + 1.month).month]
      expect(last_months_names.size).to eq 12
    end

  end

end
