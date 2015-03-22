FactoryGirl.define do
  factory :appliance_type, class: 'Atmosphere::ApplianceType' do
    name { Faker::Lorem.words(10).join(' ') }

    trait :all_attributes_not_empty do
      description { Faker::Lorem.words(10).join(' ') }
      shared true
      scalable true
      preference_cpu 2
      preference_memory 1024
      preference_disk 10240
    end

    trait :shareable do
      shared true
    end

    trait :not_shareable do
      shared false
    end

    trait :active do
      virtual_machine_templates { [ build(:virtual_machine_template)] }
    end

    # If no os_family has been specified by the requestor, bind this appliance to the first available os_family
    after(:build) do |atype|
      if atype.os_family.blank?
        atype.os_family = Atmosphere::OSFamily.first
      end
    end

    factory :filled_appliance_type, traits: [:all_attributes_not_empty]
    factory :shareable_appliance_type, traits: [:shareable]
    factory :not_shareable_appliance_type, traits: [:not_shareable]
    factory :active_appliance_type, traits: [:active]

  end
end