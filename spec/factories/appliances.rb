FactoryGirl.define do
  factory :appliance, class: 'Atmosphere::Appliance' do |f|
    appliance_set
    appliance_configuration_instance
    appliance_type
    name { SecureRandom.hex(4) }
    description { SecureRandom.hex(4) }

    compute_sites Atmosphere::ComputeSite.all

    # Create a rich fund by default so there's no risk of interfering with non-billing tests.
    fund { FactoryGirl.create(:fund, balance: 1000000) }
    # Use arbitrary last billing date
    last_billing Date.parse('2014-01-14 12:00')
    prepaid_until Date.parse('2014-02-08 12:00')

    trait :dev_mode do
      appliance_set { create(:dev_appliance_set) }
    end

    factory :appl_dev_mode, traits: [:dev_mode]
  end
end