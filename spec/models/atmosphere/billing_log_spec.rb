require 'rails_helper'

describe Atmosphere::BillingLog do

  describe '#last_year' do

    let!(:bl1) { create(:billing_log) }
    let!(:bl2) { create(:billing_log, timestamp: Time.now - 11.months) }
    let!(:bl3) { create(:billing_log, timestamp: Time.now - 12.months - 1.day) }
    let!(:bl4) { create(:billing_log, timestamp: Time.now + 1.day) }

    it 'gets proper list of logs' do
      last_year_logs = Atmosphere::BillingLog.last_year
      expect(last_year_logs).to include bl1
      expect(last_year_logs).to include bl2
      expect(last_year_logs).not_to include bl3
      expect(last_year_logs).not_to include bl4
    end

  end

end
