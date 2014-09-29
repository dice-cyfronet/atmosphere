# def rand_str(l = 4)
#   SecureRandom.hex(l)
# end

# FactoryGirl.define do

#   factory :appliance do |f|
#     appliance_set
#     appliance_configuration_instance
#     appliance_type
#     name { rand_str }
#     description { rand_str }

#     compute_sites ComputeSite.all

#     # Create a rich fund by default so there's no risk of interfering with non-billing tests.
#     fund { FactoryGirl.create(:fund, :balance => 1000000) }
#     # Use arbitrary last billing date
#     last_billing Date.parse('2014-01-14 12:00')
#     prepaid_until Date.parse('2014-02-08 12:00')

#     trait :dev_mode do
#       appliance_set { create(:dev_appliance_set) }
#     end

#     factory :appl_dev_mode, traits: [:dev_mode]
#   end

#   factory :appliance_configuration_instance do |f|
#     payload { Faker::Lorem.words(10).join(' ') }
#   end

#   factory :appliance_configuration_template do |f|
#     name { Faker::Lorem.words(10).join(' ') }
#     appliance_type

#     trait :static do
#       payload 'static initial configuration'
#     end

#     factory :static_config_template, traits: [:static]
#   end

#   factory :appliance_set do |f|
#     name 'AS'
#     user

#     trait :development do
#       appliance_set_type :development
#     end

#     trait :workflow do
#       appliance_set_type :workflow
#     end

#     trait :portal do
#       appliance_set_type :portal
#     end

#     factory :dev_appliance_set, traits: [:development]
#     factory :workflow_appliance_set, traits: [:workflow]
#     factory :portal_appliance_set, traits: [:portal]
#   end

#   factory :compute_site, aliases: [:openstack_compute_site] do |f|
#     site_id { rand_str }
#     name { rand_str }
#     site_type 'private'
#     technology 'openstack'
#     config '{"provider": "openstack", "openstack_auth_url":  "http://10.10.0.2:5000/v2.0/tokens", "openstack_api_key":  "dummy", "openstack_username": "dummy"}'
#     http_proxy_url { Faker::Internet.uri('http') }
#     https_proxy_url { Faker::Internet.uri('https') }

#     # Create 4 VM flavors for this compute_site by default
#     # virtual_machine_flavors { FactoryGirl.create_list(:virtual_machine_flavor, 4) }

#     trait :openstack_flavors do
#       virtual_machine_flavors { [
#         build(:virtual_machine_flavor, flavor_name: 'flavor 1', cpu: 1, memory: 512, hdd: 30, hourly_cost: 10, id_at_site: '1'),
#         build(:virtual_machine_flavor, flavor_name: 'flavor 2', cpu: 1, memory: 2048, hdd: 30, hourly_cost: 20, id_at_site: '2'),
#         build(:virtual_machine_flavor, flavor_name: 'flavor 3', cpu: 2, memory: 4096, hdd: 30, hourly_cost: 30, id_at_site: '3'),
#         build(:virtual_machine_flavor, flavor_name: 'flavor 4', cpu: 4, memory: 8192, hdd: 30, hourly_cost: 40, id_at_site: '4'),
#         build(:virtual_machine_flavor, flavor_name: 'flavor 5', cpu: 8, memory: 16384, hdd: 30, hourly_cost: 50, id_at_site: '5')
#       ] }
#     end

#     trait :amazon_flavors do
#       virtual_machine_flavors { [
#         build(:virtual_machine_flavor, flavor_name: 'micro flavor', cpu: 1, memory: 615, hdd: 0, hourly_cost: 60, id_at_site: 't1.micro'),
#         build(:virtual_machine_flavor, flavor_name: 'small flavor', cpu: 1, memory: 1740, hdd: 150, hourly_cost: 70, id_at_site: 'm1.small'),
#         build(:virtual_machine_flavor, flavor_name: 'medium flavor', cpu: 2, memory: 3840, hdd: 400, hourly_cost: 80, id_at_site: 'm1.medium'),
#         build(:virtual_machine_flavor, flavor_name: 'large flavor', cpu: 4, memory: 7680, hdd: 840, hourly_cost: 90, id_at_site: 'm1.large'),
#         build(:virtual_machine_flavor, flavor_name: 'xlarge flavor', cpu: 8, memory: 15360, hdd: 1680, hourly_cost: 100, id_at_site: 'm1.xlarge')
#       ] }
#     end

#     factory :amazon_with_flavors, traits: [:amazon_flavors] do
#       site_type 'public'
#       technology 'aws'
#       #config '{"provider":"aws", "aws_access_key_id":"wrong", "aws_secret_access_key":"wrong", "region":"eu-west-1"}'
#     end

#     factory :amazon_compute_site do
#       site_type 'public'
#       technology 'aws'
#       config '{"provider":"aws", "aws_access_key_id":"wrong", "aws_secret_access_key":"wrong", "region":"eu-west-1"}'
#     end

#     factory :openstack_with_flavors, traits: [:openstack_flavors]
#   end

#   factory :appliance_type do
#     name { Faker::Lorem.words(10).join(' ') }

#     trait :all_attributes_not_empty do
#       description { Faker::Lorem.words(10).join(' ') }
#       shared true
#       scalable true
#       preference_cpu 2
#       preference_memory 1024
#       preference_disk 10240
#       security_proxy
#     end

#     trait :shareable do
#       shared true
#     end

#     trait :not_shareable do
#       shared false
#     end

#     trait :active do
#       virtual_machine_templates { [ build(:virtual_machine_template)] }
#     end

#     factory :filled_appliance_type, traits: [:all_attributes_not_empty]
#     factory :shareable_appliance_type, traits: [:shareable]
#     factory :not_shareable_appliance_type, traits: [:not_shareable]
#     factory :active_appliance_type, traits: [:active]

#   end

#   factory :dev_mode_property_set do |f|
#     name 'AS'
#     appliance
#   end

#   factory :endpoint do |f|
#     name { rand_str }
#     port_mapping_template
#     invocation_path { rand_str }
#   end

#   factory :fund do
#     name { FactoryGirl.generate(:fund_name) }
#     balance { rand(max=1000000) }
#     overdraft_limit { 0-rand(max=10000) }
#     termination_policy { "suspend" }
#   end

#   sequence :fund_name do |n|
#     "Fund #{n}"
#   end

#   factory :http_mapping do |f|
#     url  Faker::Internet.domain_name
#     application_protocol "http"
#     base_url "http://base.url"
#     appliance
#     port_mapping_template
#     compute_site
#   end

#   factory :port_mapping do |f|
#     public_ip '8.8.8.8'
#     source_port { 2000 + Random.rand(20000) }
#     port_mapping_template
#     virtual_machine
#   end

#   factory :port_mapping_property do |f|
#     value { Faker::Lorem.words(10).join(' ') }
#     key { rand_str }
#     compute_site

#     trait :pmt_property do
#       compute_site nil
#       port_mapping_template
#     end

#     factory :pmt_property, traits: [:pmt_property]
#   end

#   factory :port_mapping_template do |f|
#     service_name { rand_str }
#     target_port { Random.rand(9999) }
#     appliance_type

#     trait :devel do
#       appliance_type nil
#       dev_mode_property_set
#     end

#     factory  :dev_port_mapping_template, traits: [:devel]
#   end

#   factory :security_policy do |f|
#     name 'security/policy'
#     payload { Faker::Lorem.words(10).join(' ') }
#   end

#   factory :security_proxy do |f|
#     name 'security/proxy'
#     payload { Faker::Lorem.words(10).join(' ') }
#   end

#   factory :user do
#     email { Faker::Internet.email }
#     login { rand_str }
#     password '12345678'
#     password_confirmation { password }
#     authentication_token { login }

#     # Create 2 funds for this user by default
#     funds { FactoryGirl.create_list(:fund, 2) }

#     trait :developer do
#       roles [:developer]
#     end

#     trait :admin do
#       roles [:admin]
#     end

#     trait :authentication_token do

#     end

#     factory :developer, traits: [:developer]
#     factory :admin, traits: [:admin]
#   end

#   factory :user_key do |f|
#     name { Faker::Lorem.words(10).join(' ') }
#     public_key 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q== factorized@sting'
#     fingerprint 'rubbish! Real fingrprint is calculated in after_initialize method in model'
#     user
#   end

#   factory :virtual_machine do |f|
#     name { Faker::Internet.user_name }
#     id_at_site { Faker::Internet.ip_v4_address }
#     state :active
#     source_template
#     compute_site

#     # By default, assign some random VM flavor which belongs to this VM's compute_site
#     virtual_machine_flavor { self.compute_site.virtual_machine_flavors.first }

#     trait :active_vm do
#       ip { Faker::Internet.ip_v4_address }
#     end

#     factory :active_vm, traits: [:active_vm]
#   end

#   factory :virtual_machine_flavor, aliases: [:flavor] do
#     flavor_name { FactoryGirl.generate(:vm_flavor_name) }
#     cpu { rand(max=16) + 1 }
#     memory { rand(max=16384) + 512 }
#     hdd { rand(max=1000) + 1 }
#     hourly_cost { rand(max=100) + 1 }
#   end

#   factory :virtual_machine_template, aliases: [:source_template] do |f|
#     compute_site
#     name { Faker::Lorem.characters(5) }
#     id_at_site { Faker::Internet.ip_v4_address }
#     state :active

#     trait :managed_vmt do
#       managed_by_atmosphere true
#     end

#     factory :managed_vmt, traits: [:managed_vmt]
#   end

#   sequence :vm_flavor_name do |n|
#     "Flavor #{n}"
#   end
# end