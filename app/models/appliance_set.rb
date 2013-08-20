# == Schema Information
#
# Table name: appliance_sets
#
#  id                 :integer          not null, primary key
#  context_id         :string(255)      not null
#  priority           :integer          default(50), not null
#  appliance_set_type :string(255)      default("development"), not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#

class ApplianceSet < ActiveRecord::Base

  validates_presence_of :name
  validates_presence_of :context_id, :priority, :appliance_set_type, :user_id
  validates_uniqueness_of :context_id

  validates :priority, numericality: { only_integer: true }, inclusion: 1..100

  validates :appliance_set_type, inclusion: %w(portal development workflow)
  validates :appliance_set_type, uniqueness: { scope: :user }, if: 'appliance_set_type == "development"'

  attr_readonly :context_id, :appliance_set_type


  belongs_to :user
  validates :user, presence: true  # This should also make sure the User exists

end
