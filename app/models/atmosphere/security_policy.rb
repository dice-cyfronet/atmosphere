# == Schema Information
#
# Table name: security_policies
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  payload    :text
#  created_at :datetime
#  updated_at :datetime
#
module Atmosphere
  class SecurityPolicy < ActiveRecord::Base
    self.table_name = 'security_policies'

    include OwnedPayloable
  end
end
