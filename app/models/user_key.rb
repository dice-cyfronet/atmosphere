# == Schema Information
#
# Table name: user_keys
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  fingerprint :string(255)
#  public_key  :text
#  user_id     :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

class UserKey < ActiveRecord::Base
  belongs_to :user
end
