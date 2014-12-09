# == Schema Information
#
# Table name: compute_site_funds
#
#  id              :integer          not null, primary key
#  compute_site_id :integer
#  fund_id         :integer
#

# Linking table between ComputeSites and Funds
module Atmosphere
  class ComputeSiteFund < ActiveRecord::Base
    belongs_to :compute_site,
      class_name: 'Atmosphere::ComputeSite'

    belongs_to :fund,
      class_name: 'Atmosphere::Fund'

    validates :compute_site_id,
              uniqueness: { scope: :fund_id, message: I18n.t('funds.unique_compute_site') }
  end
end
