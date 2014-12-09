FactoryGirl.define do
  factory :compute_site_fund, class: 'Atmosphere::ComputeSiteFund' do |f|
    fund
    compute_site
  end
end
