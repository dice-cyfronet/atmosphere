FactoryGirl.define do
  factory :endpoint, class: 'Atmosphere::Endpoint' do |f|
    name { SecureRandom.hex(4) }
    port_mapping_template
    invocation_path { SecureRandom.hex(4) }
  end
end