# Linking table between Users and Funds
class UserFund < ActiveRecord::Base

  belongs_to :user
  belongs_to :fund

end
