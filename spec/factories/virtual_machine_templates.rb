FactoryGirl.define do
  factory :virtual_machine_template, aliases: [:source_template], class: 'Atmosphere::VirtualMachineTemplate' do |f|
    name { FFaker::Lorem.characters(5) }
    id_at_site { FFaker::Internet.ip_v4_address }
    state :active

    tenants { [FactoryGirl.create(:tenant)] }

    trait :managed_vmt do
      managed_by_atmosphere true
    end

    factory :managed_vmt, traits: [:managed_vmt]
  end
end