class ApplianceConfigurationTemplate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name, scope: :appliance_type

  belongs_to :appliance_type
  validates_presence_of :appliance_type

  has_many :appliance_configuration_instances
end
