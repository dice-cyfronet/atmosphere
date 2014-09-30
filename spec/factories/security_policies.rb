FactoryGirl.define do
  factory :security_policy, class: 'Atmosphere::SecurityPolicy' do |f|
    name 'security/policy'
    payload { Faker::Lorem.words(10).join(' ') }
  end
end