FactoryGirl.define do
  factory :dev_mode_property_set, class: 'Atmosphere::DevModePropertySet' do |f|
    name 'AS'
    appliance
  end
end