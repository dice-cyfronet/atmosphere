FactoryGirl.define do

  factory :user do
    email { Faker::Internet.email }
    password '12345678'
    password_confirmation { password }
    authentication_token 'secret'
  end

  factory :appliance_set do |f|
    #name 'AS'
    f.context_id 'ctx'
    f.association :user
  end

end