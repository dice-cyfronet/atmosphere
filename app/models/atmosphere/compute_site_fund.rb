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
  end
end
