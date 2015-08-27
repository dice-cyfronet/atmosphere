FactoryGirl.define do
  factory :appliance, class: 'Atmosphere::Appliance' do |f|
    appliance_set
    appliance_configuration_instance
    appliance_type
    name { SecureRandom.hex(4) }
    description { SecureRandom.hex(4) }
    last_billing Date.parse('2014-01-14 12:00')

    tenants Atmosphere::Tenant.all

    after(:build) do |appliance|
      appliance.deployments.each do |dep|
        # Initialize deployment billing, if present
        dep.prepaid_until = Time.now.utc
      end
    end

    trait :dev_mode do
      appliance_set { create(:dev_appliance_set) }
    end

    factory :appl_dev_mode, traits: [:dev_mode]
  end
end