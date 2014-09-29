FactoryGirl.define do
  factory :fund, class: 'Atmosphere::Fund' do
    name { FactoryGirl.generate(:fund_name) }
    balance { rand(max=1000000) }
    overdraft_limit { 0-rand(max=10000) }
    termination_policy { "suspend" }
  end

  sequence :fund_name do |n|
    "Fund #{n}"
  end
end