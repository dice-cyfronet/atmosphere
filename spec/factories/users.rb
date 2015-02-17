FactoryGirl.define do
  factory :user, class: 'Atmosphere::User' do
    email { Faker::Internet.email }
    login { SecureRandom.hex(8) }
    password '12345678'
    password_confirmation { password }
    authentication_token { login }

    # Create 2 funds for this user by default
    funds { FactoryGirl.create_list(:fund, 2) }

    trait :developer do
      roles [:developer]
    end

    trait :admin do
      roles [:admin]
    end

    trait :authentication_token do

    end

    factory :developer, traits: [:developer]
    factory :admin, traits: [:admin]
  end

  # Test user with no (explicitly appointed) funds
  factory :poor_chap, class: 'Atmosphere::User' do
    email { Faker::Internet.email }
    login { SecureRandom.hex(8) }
    password '12345678'
    password_confirmation { password }
  end
end
