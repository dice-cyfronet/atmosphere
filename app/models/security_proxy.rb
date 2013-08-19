class SecurityProxy < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates :name, presence: true, uniqueness: true, :format => { :with => /\A[\w-]+(\/{0,1}[\w-]+)+\Z/ }
  validates_presence_of :payload
end
