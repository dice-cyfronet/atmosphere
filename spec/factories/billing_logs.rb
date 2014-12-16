FactoryGirl.define do
  factory :billing_log, class: 'Atmosphere::BillingLog' do
    user
    currency { 'EUR' }
    amount_billed { 10000 }
    timestamp { Time.now }
  end
end
