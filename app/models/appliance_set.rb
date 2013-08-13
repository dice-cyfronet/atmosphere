# == Schema Information
#
# Table name: appliancesets
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  context_id    :string(255)      not null
#  priority      :integer          default(50), not null
#  appliance_set_type :string(255)      default("development"), not null
#  created_at    :datetime
#  updated_at    :datetime
#

class ApplianceSet < ActiveRecord::Base

  validates_presence_of :name, :context_id, :priority, :appliance_set_type
  validates_uniqueness_of :context_id

  validates :priority, numericality: { only_integer: true }, inclusion: 1..100

  validates :appliance_set_type, inclusion: %w(portal development workflow)

  attr_readonly :context_id, :appliance_set_type

end
