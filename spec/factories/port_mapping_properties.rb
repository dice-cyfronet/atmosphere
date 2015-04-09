FactoryGirl.define do
  factory :port_mapping_property, class: 'Atmosphere::PortMappingProperty' do |f|
    value { FFaker::Lorem.words(10).join(' ') }
    key { SecureRandom.hex(4) }
    compute_site

    trait :pmt_property do
      compute_site nil
      port_mapping_template
    end

    factory :pmt_property, traits: [:pmt_property]
  end
end