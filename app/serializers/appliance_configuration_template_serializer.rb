class ApplianceConfigurationTemplateSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :payload
  has_one :appliance_type
end