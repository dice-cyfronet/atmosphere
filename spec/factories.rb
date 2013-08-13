FactoryGirl.define do

  factory :user do
    email { Faker::Internet.email }
    password '12345678'
    password_confirmation { password }
    authentication_token 'secret'
  end

  factory :appliance_set do
    name 'AS'
    context_id 'ctx'
  end

end