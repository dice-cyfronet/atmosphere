def rand_str(l = 4)
  SecureRandom.hex(l)
end

FactoryGirl.define do

  factory :user do
    email { Faker::Internet.email }
    login { rand_str }
    password '12345678'
    password_confirmation { password }
    authentication_token { login }

    # Create 2 funds for this user by default
    funds { FactoryGirl.create_list(:fund, 2) }

    trait :developer do
      roles [:developer]
    end

    trait :admin do
      roles [:admin]
    end

    trait :authentication_token do

    end

    factory :developer, traits: [:developer]
    factory :admin, traits: [:admin]
  end

  factory :appliance_set do |f|
    name 'AS'
    user

    trait :development do
      appliance_set_type :development
    end

    trait :workflow do
      appliance_set_type :workflow
    end

    trait :portal do
      appliance_set_type :portal
    end

    factory :dev_appliance_set, traits: [:development]
    factory :workflow_appliance_set, traits: [:workflow]
    factory :portal_appliance_set, traits: [:portal]
  end

  factory :appliance_type do
    name { Faker::Lorem.words(10).join(' ') }

    trait :all_attributes_not_empty do
      description { Faker::Lorem.words(10).join(' ') }
      shared true
      scalable true
      preference_cpu 2
      preference_memory 1024
      preference_disk 10240
      security_proxy
    end

    trait :shareable do
      shared true
    end

    trait :not_shareable do
      shared false
    end

    factory :filled_appliance_type, traits: [:all_attributes_not_empty]
    factory :shareable_appliance_type, traits: [:shareable]
    factory :not_shareable_appliance_type, traits: [:not_shareable]
  end

  factory :appliance do |f|
    appliance_set
    appliance_configuration_instance
    appliance_type
    name { rand_str }

    # Create a rich fund by default so there's no risk of interfering with non-billing tests.
    fund { FactoryGirl.create(:fund, :balance => 1000000) }
    # Use arbitrary last billing date
    last_billing Date.parse('2014-01-14 12:00')
    prepaid_until Date.parse('2014-02-08 12:00')

    trait :dev_mode do
      appliance_set { create(:dev_appliance_set) }
    end

    factory :appl_dev_mode, traits: [:dev_mode]
  end

  factory :security_proxy do |f|
    name 'security/proxy'
    payload { Faker::Lorem.words(10).join(' ') }
  end

  factory :security_policy do |f|
    name 'security/policy'
    payload { Faker::Lorem.words(10).join(' ') }
  end

  factory :appliance_configuration_template do |f|
    name { Faker::Lorem.words(10).join(' ') }
    appliance_type

    trait :static do
      payload 'static initial configuration'
    end

    factory :static_config_template, traits: [:static]
  end

  factory :compute_site, aliases: [:openstack_compute_site] do |f|
    site_id { rand_str }
    name { rand_str }
    site_type 'private'
    technology 'openstack'
    config '{"provider": "openstack", "openstack_auth_url":  "http://10.10.0.2:5000/v2.0/tokens", "openstack_api_key":  "dummy", "openstack_username": "dummy"}'

    # Create 4 VM flavors for this compute_site by default
    virtual_machine_flavors { FactoryGirl.create_list(:virtual_machine_flavor, 4) }

    trait :openstack_flavors do
      virtual_machine_flavors { [
        build(:virtual_machine_flavor, flavor_name: '1', cpu: 1, memory: 512, hdd: 30, hourly_cost: 1),
        build(:virtual_machine_flavor, flavor_name: '2', cpu: 1, memory: 2048, hdd: 30, hourly_cost: 2),
        build(:virtual_machine_flavor, flavor_name: '3', cpu: 2, memory: 4096, hdd: 30, hourly_cost: 3),
        build(:virtual_machine_flavor, flavor_name: '4', cpu: 4, memory: 8192, hdd: 30, hourly_cost: 4),
        build(:virtual_machine_flavor, flavor_name: '5', cpu: 8, memory: 16384, hdd: 30, hourly_cost: 5)
      ] }
    end

    trait :amazon_flavors do
      virtual_machine_flavors { [
        build(:virtual_machine_flavor, flavor_name: 't1.micro', cpu: 1, memory: 615, hdd: 0, hourly_cost: 6),
        build(:virtual_machine_flavor, flavor_name: 'm1.small', cpu: 1, memory: 1740, hdd: 150, hourly_cost: 7),
        build(:virtual_machine_flavor, flavor_name: 'm1.medium', cpu: 2, memory: 3840, hdd: 400, hourly_cost: 8),
        build(:virtual_machine_flavor, flavor_name: 'm1.large', cpu: 4, memory: 7680, hdd: 840, hourly_cost: 9),
        build(:virtual_machine_flavor, flavor_name: 'm1.xlarge', cpu: 8, memory: 15360, hdd: 1680, hourly_cost: 10)
      ] }
    end

    factory :amazon_with_flavors, traits: [:amazon_flavors] do
      site_type 'public'
      technology 'aws'
    end
    factory :openstack_with_flavors, traits: [:openstack_flavors]
  end

  sequence :vm_flavor_name do |n|
    "Flavor #{n}"
  end

  factory :virtual_machine_flavor do
    flavor_name { FactoryGirl.generate(:vm_flavor_name) }
    cpu { rand(max=16) }
    memory { rand(max=16384) }
    hdd { rand(max=1000) }
    hourly_cost { rand(max=100) }
  end

  sequence :fund_name do |n|
    "Fund #{n}"
  end

  factory :fund do
    name { FactoryGirl.generate(:fund_name) }
    balance { rand(max=1000000) }
    overdraft_limit { 0-rand(max=10000) }
    termination_policy { "suspend" }
  end

  factory :user_key do |f|
    name { Faker::Lorem.words(10).join(' ') }
    public_key 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q== factorized@sting'
    fingerprint 'rubbish! Real fingrprint is calculated in after_initialize method in model'
    user
  end

  factory :port_mapping do |f|
    public_ip '8.8.8.8'
    source_port { 2000 + Random.rand(20000) }
    port_mapping_template
    virtual_machine
  end

  factory :port_mapping_template do |f|
    service_name { rand_str }
    target_port { Random.rand(9999) }
    appliance_type

    trait :devel do
      appliance_type nil
      dev_mode_property_set
    end

    factory  :dev_port_mapping_template, traits: [:devel]
  end

  factory :endpoint do |f|
    name { rand_str }
    port_mapping_template
    invocation_path { rand_str }
  end

  factory :port_mapping_property do |f|
    value { Faker::Lorem.words(10).join(' ') }
    key { rand_str }
    compute_site

    trait :pmt_property do
      compute_site nil
      port_mapping_template
    end

    factory :pmt_property, traits: [:pmt_property]
  end

  factory :appliance_configuration_instance do |f|
    payload { Faker::Lorem.words(10).join(' ') }
  end

  factory :dev_mode_property_set do |f|
    name 'AS'
    appliance
  end

  factory :virtual_machine_template, aliases: [:source_template] do |f|
    compute_site
    name { Faker::Internet.user_name }
    id_at_site { Faker::Internet.ip_v4_address }
    state :active
  end

  factory :virtual_machine do |f|
    name { Faker::Internet.user_name }
    id_at_site { Faker::Internet.ip_v4_address }
    state :active
    source_template
    compute_site

    # By default, assign some random VM flavor which belongs to this VM's compute_site
    virtual_machine_flavor { self.compute_site.virtual_machine_flavors.first }
  end

  factory :http_mapping do |f|
    url  Faker::Internet.domain_name
    application_protocol "http"
    appliance
    port_mapping_template
  end

end