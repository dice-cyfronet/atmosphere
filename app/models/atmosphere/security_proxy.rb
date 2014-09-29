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
module Atmosphere
  class SecurityProxy < ActiveRecord::Base
    self.table_name = 'security_proxies'

    include OwnedPayloable

    has_many :appliance_types
    has_many :dev_mode_property_sets, dependent: :nullify
  end
end
