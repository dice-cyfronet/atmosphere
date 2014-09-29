FactoryGirl.define do
  factory :port_mapping, class: 'Atmosphere::PortMapping' do |f|
    public_ip '8.8.8.8'
    source_port { 2000 + Random.rand(20000) }
    port_mapping_template
    virtual_machine
  end
end