# == Schema Information
#
# Table name: compute_site_funds
#
#  id              :integer          not null, primary key
#  compute_site_id :integer
#  fund_id         :integer
#

# Linking table between ComputeSites and Funds
class ComputeSiteFund < ActiveRecord::Base

  belongs_to :compute_site
  belongs_to :fund

end
