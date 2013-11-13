class ApplianceConfigurationInstanceSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :payload
  has_one :appliance_configuration_template
  has_many :appliances
end