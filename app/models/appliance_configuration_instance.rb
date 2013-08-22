class ApplianceConfigurationInstance < ActiveRecord::Base
  has_many :appliances
  belongs_to :appliance_configuration_template
  validates :appliance_configuration_template, presence: true
end
