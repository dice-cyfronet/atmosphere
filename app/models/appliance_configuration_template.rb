# == Schema Information
#
# Table name: appliance_configuration_templates
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  payload           :text
#  appliance_type_id :integer          not null
#  created_at        :datetime
#  updated_at        :datetime
#

class ApplianceConfigurationTemplate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name, scope: :appliance_type

  belongs_to :appliance_type
  validates_presence_of :appliance_type

  has_many :appliance_configuration_instances, dependent: :destroy
end
