# Linking table between ComputeSites and Funds
class ComputeSiteFund < ActiveRecord::Base

  belongs_to :compute_site
  belongs_to :fund

end
