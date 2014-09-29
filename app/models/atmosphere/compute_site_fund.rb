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
    self.table_name = 'compute_site_funds'

    belongs_to :compute_site
    belongs_to :fund
  end
end
