# == Schema Information
#
# Table name: user_funds
#
#  id      :integer          not null, primary key
#  user_id :integer
#  fund_id :integer
#  default :boolean          default(FALSE)
#

# Linking table between Users and Funds
module Atmosphere
  class UserFund < ActiveRecord::Base
    belongs_to :user,
      class_name: 'Atmosphere::User'

    belongs_to :fund,
      class_name: 'Atmosphere::Fund'
  end
end
