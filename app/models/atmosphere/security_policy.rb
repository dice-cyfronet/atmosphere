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

class SecurityPolicy < ActiveRecord::Base
  include OwnedPayloable
end
