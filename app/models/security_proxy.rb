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
  has_and_belongs_to_many :users


  validates_presence_of :payload

  def self.name_regex
    '[\w-]+(\/{0,1}[\w-]+)+'
  end

  validates :name, presence: true, uniqueness: true, :format => { :with => /\A#{SecurityProxy.name_regex}\z/ }
end
