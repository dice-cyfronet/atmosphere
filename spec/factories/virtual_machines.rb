FactoryGirl.define do
  factory :virtual_machine, class: 'Atmosphere::VirtualMachine' do |f|
    name { FFaker::Internet.user_name }
    id_at_site { FFaker::Internet.ip_v4_address }
    state :active
    source_template
    tenant

    # By default, assign some random VM flavor which belongs to this VM's tenants
    virtual_machine_flavor { self.tenant.virtual_machine_flavors.first }

    trait :active_vm do
      ip { FFaker::Internet.ip_v4_address }
    end

    factory :active_vm, traits: [:active_vm]
  end
end