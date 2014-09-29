FactoryGirl.define do
  factory :virtual_machine, class: 'Atmosphere::VirtualMachine' do |f|
    name { Faker::Internet.user_name }
    id_at_site { Faker::Internet.ip_v4_address }
    state :active
    source_template
    compute_site

    # By default, assign some random VM flavor which belongs to this VM's compute_site
    virtual_machine_flavor { self.compute_site.virtual_machine_flavors.first }

    trait :active_vm do
      ip { Faker::Internet.ip_v4_address }
    end

    factory :active_vm, traits: [:active_vm]
  end
end