# == Schema Information
#
# Table name: compute_site_funds
#
#  id              :integer          not null, primary key
#  compute_site_id :integer
#  fund_id         :integer
#

# Linking table between Fenants and Funds
module Atmosphere
  class TenantFund < ActiveRecord::Base
    belongs_to :tenant,
               class_name: 'Atmosphere::Tenant'

    belongs_to :fund,
               class_name: 'Atmosphere::Fund'

    validates :tenant_id,
              uniqueness: {
                scope: :fund_id,
                message: I18n.t('funds.unique_compute_site')
              }
  end
end
