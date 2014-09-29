FactoryGirl.define do
  factory :appliance_set, class: 'Atmosphere::ApplianceSet' do |f|
    name 'AS'
    user

    trait :development do
      appliance_set_type :development
    end

    trait :workflow do
      appliance_set_type :workflow
    end

    trait :portal do
      appliance_set_type :portal
    end

    factory :dev_appliance_set, traits: [:development]
    factory :workflow_appliance_set, traits: [:workflow]
    factory :portal_appliance_set, traits: [:portal]
  end
end