FactoryGirl.define do
  factory :port_mapping_property, class: 'Atmosphere::PortMappingProperty' do |f|
    value { FFaker::Lorem.words(10).join(' ') }
    key { SecureRandom.hex(4) }
    tenant

    trait :pmt_property do
      tenant nil
      port_mapping_template
    end

    factory :pmt_property, traits: [:pmt_property]
  end
end