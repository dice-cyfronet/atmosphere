FactoryGirl.define do
  factory :port_mapping_template, class: 'Atmosphere::PortMappingTemplate' do
    service_name { SecureRandom.hex(4) }
    target_port { SecureRandom.random_number(9999) }
    appliance_type

    trait :devel do
      appliance_type nil
      dev_mode_property_set
    end

    factory :dev_port_mapping_template, traits: [:devel]
  end
end
