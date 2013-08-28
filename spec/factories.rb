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
  end

  factory :appliance_type do
    name { Faker::Lorem.words(10).join(' ') }
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
  end

  factory :compute_site do |f|
    site_id 'factorized'
    name 'Factoriez'
    site_type 'private'
    technology 'openstack'
  end

  factory :user_key do |f|
    name 'factorized'
    public_key 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q== factorized@sting'
    fingerprint 'rubbish! Real fingrprint is calculated in after_initialize method in model'
    user
  end

  factory :port_mapping_template do |f|
    service_name { Faker::Lorem.word }
    target_port { Random.rand(9999) }
    appliance_type
  end

  factory :appliance_configuration_instance do |f|
    payload { Faker::Lorem.words(10).join(' ') }
  end

  factory :appliance do |f|
    appliance_set
    appliance_configuration_instance
    appliance_type
  end

<<<<<<< HEAD
  factory :dev_mode_property_set do |f|
    name 'AS'
    appliance
  end
=======
>>>>>>> origin/master
end