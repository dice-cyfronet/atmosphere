# == Schema Information
#
# Table name: security_proxies
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  payload    :text
#  created_at :datetime
#  updated_at :datetime
#

class SecurityProxy < ActiveRecord::Base
  include OwnedPayloable

  has_many :appliance_types
  has_many :dev_mode_property_sets, dependent: :nullify
end
