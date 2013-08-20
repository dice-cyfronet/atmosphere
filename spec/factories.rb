FactoryGirl.define do

  factory :user do
    email { Faker::Internet.email }
    login { Faker::Internet.user_name }
    password '12345678'
    password_confirmation { password }
    authentication_token { login }
  end

  factory :appliance_set do |f|
    name 'AS'
    f.context_id 'ctx'
    f.association :user
  end

  factory :security_proxy do |f|
    name 'security/proxy'
    payload { Faker::Lorem.words(10).join(' ') }
  end

  factory :appliance_type do
    name 'AT'
  end

end