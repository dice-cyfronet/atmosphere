FactoryGirl.define do
  factory :user_appliance_type, class: 'Atmosphere::UserApplianceType' do |uat|
    user
    appliance_type
    role 'reader'
  end
end
