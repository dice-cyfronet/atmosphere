FactoryGirl.define do
  factory :security_proxy, class: 'Atmosphere::SecurityProxy' do |f|
    name 'security/proxy'
    payload { Faker::Lorem.words(10).join(' ') }
  end
end