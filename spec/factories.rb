FactoryGirl.define do

  factory :user do
    email { Faker::Internet.email }
    login { Faker::Internet.user_name }
    password '12345678'
    password_confirmation { password }
    authentication_token { login }

    trait :developer do
      roles [:developer]
    end

    trait :admin do
      roles [:admin]
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

    factory :filled_appliance_type, traits: [:all_attributes_not_empty]
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

  factory :compute_site do |f|
    site_id { SecureRandom.hex(4) }
    name { SecureRandom.hex(4) }
    site_type 'private'
    config 'dummy config'
  end

  factory :user_key do |f|
    name { Faker::Lorem.words(10).join(' ') }
    public_key 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q== factorized@sting'
    fingerprint 'rubbish! Real fingrprint is calculated in after_initialize method in model'
    user
  end

  factory :port_mapping_template do |f|
    service_name { Faker::Lorem.word }
    target_port { Random.rand(9999) }
    appliance_type
  end

  factory :endpoint do |f|
    port_mapping_template
  end

  factory :port_mapping_property do |f|
    value { Faker::Lorem.words(10).join(' ') }
    key 'key'
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

  factory :appliance do |f|
    appliance_set
    appliance_configuration_instance
    appliance_type
  end

  factory :dev_mode_property_set do |f|
    name 'AS'
    appliance
  end

  factory :virtual_machine_template do |f|
    compute_site
    name { Faker::Internet.user_name }
    id_at_site { Faker::Internet.ip_v4_address }
    state :active
  end
end