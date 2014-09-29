FactoryGirl.define do
  factory :appliance_configuration_template,
    class: 'Atmosphere::ApplianceConfigurationTemplate' do |f|
    name { Faker::Lorem.words(10).join(' ') }
    appliance_type

    trait :static do
      payload 'static initial configuration'
    end

    factory :static_config_template, traits: [:static]
  end
end