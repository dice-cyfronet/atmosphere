FactoryGirl.define do

  factory :user do
    email { Faker::Internet.email }
    password "12345678"
    password_confirmation { password }
    authentication_token 'secret'
  end
end