class ApplianceSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :appliance_set_id, :appliance_type_id
  has_one :appliance_configuration_instance
end