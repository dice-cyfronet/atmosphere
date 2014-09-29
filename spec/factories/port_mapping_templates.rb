FactoryGirl.define do
  factory :port_mapping_template, class: 'Atmosphere::PortMappingTemplate' do |f|
    service_name { SecureRandom.hex(4) }
    target_port { Random.rand(9999) }
    appliance_type

    trait :devel do
      appliance_type nil
      dev_mode_property_set
    end

    factory  :dev_port_mapping_template, traits: [:devel]
  end
end