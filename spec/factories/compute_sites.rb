FactoryGirl.define do
  factory :compute_site, aliases: [:openstack_compute_site], class: 'Atmosphere::ComputeSite' do |f|
    site_id { SecureRandom.hex(4) }
    name { SecureRandom.hex(4) }
    site_type 'private'
    technology 'openstack'
    config '{"provider": "openstack", "openstack_auth_url":  "http://10.10.0.2:5000/v2.0/tokens", "openstack_api_key":  "dummy", "openstack_username": "dummy"}'
    http_proxy_url { Faker::Internet.uri('http') }
    https_proxy_url { Faker::Internet.uri('https') }

    # Create 4 VM flavors for this compute_site by default
    # virtual_machine_flavors { FactoryGirl.create_list(:virtual_machine_flavor, 4) }

    trait :openstack_flavors do
      virtual_machine_flavors { [
        build(:virtual_machine_flavor, flavor_name: 'flavor 1', cpu: 1, memory: 512, hdd: 30, id_at_site: '1'),
        build(:virtual_machine_flavor, flavor_name: 'flavor 2', cpu: 1, memory: 2048, hdd: 30, id_at_site: '2'),
        build(:virtual_machine_flavor, flavor_name: 'flavor 3', cpu: 2, memory: 4096, hdd: 30, id_at_site: '3'),
        build(:virtual_machine_flavor, flavor_name: 'flavor 4', cpu: 4, memory: 8192, hdd: 30, id_at_site: '4'),
        build(:virtual_machine_flavor, flavor_name: 'flavor 5', cpu: 8, memory: 16384, hdd: 30, id_at_site: '5')
      ] }
    end

    trait :amazon_flavors do
      virtual_machine_flavors { [
        build(:virtual_machine_flavor, flavor_name: 'micro flavor', cpu: 1, memory: 615, hdd: 0, id_at_site: 't1.micro'),
        build(:virtual_machine_flavor, flavor_name: 'small flavor', cpu: 1, memory: 1740, hdd: 150, id_at_site: 'm1.small'),
        build(:virtual_machine_flavor, flavor_name: 'medium flavor', cpu: 2, memory: 3840, hdd: 400, id_at_site: 'm1.medium'),
        build(:virtual_machine_flavor, flavor_name: 'large flavor', cpu: 4, memory: 7680, hdd: 840, id_at_site: 'm1.large'),
        build(:virtual_machine_flavor, flavor_name: 'xlarge flavor', cpu: 8, memory: 15360, hdd: 1680, id_at_site: 'm1.xlarge')
      ] }
    end

    factory :amazon_with_flavors, traits: [:amazon_flavors] do
      site_type 'public'
      technology 'aws'
      #config '{"provider":"aws", "aws_access_key_id":"wrong", "aws_secret_access_key":"wrong", "region":"eu-west-1"}'
    end

    factory :amazon_compute_site do
      site_type 'public'
      technology 'aws'
      config '{"provider":"aws", "aws_access_key_id":"wrong", "aws_secret_access_key":"wrong", "region":"eu-west-1"}'
    end

    factory :openstack_with_flavors, traits: [:openstack_flavors]
  end
end