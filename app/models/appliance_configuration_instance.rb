# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

class ApplianceConfigurationInstance < ActiveRecord::Base
  has_many :appliances
  belongs_to :appliance_configuration_template
  validates :appliance_configuration_template, presence: true
end
