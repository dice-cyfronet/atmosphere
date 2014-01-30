class ApplianceSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :state, :state_explanation
  has_one :appliance_configuration_instance, :appliance_set, :appliance_type
end