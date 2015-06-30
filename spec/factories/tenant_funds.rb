FactoryGirl.define do
  factory :tenant_fund, class: 'Atmosphere::TenantFund' do |f|
    fund
    tenant
  end
end
