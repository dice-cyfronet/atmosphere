FactoryGirl.define do
  factory :http_mapping, class: 'Atmosphere::HttpMapping' do |f|
    url FFaker::Internet.domain_name
    application_protocol "http"
    base_url "http://base.url"
    appliance
    port_mapping_template
    tenant
  end
end