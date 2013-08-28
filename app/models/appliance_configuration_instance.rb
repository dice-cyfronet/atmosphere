# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id                                  :integer          not null, primary key
#  payload                             :text
#  appliance_configuration_template_id :integer          not null
#  created_at                          :datetime
#  updated_at                          :datetime
#

class ApplianceConfigurationInstance < ActiveRecord::Base

  belongs_to :appliance_configuration_template

  has_many :appliances

end
