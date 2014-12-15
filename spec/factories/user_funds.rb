FactoryGirl.define do
  factory :user_fund, class: 'Atmosphere::UserFund' do |f|
    fund
    user
  end
end
