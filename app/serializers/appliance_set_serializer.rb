class ApplianceSetSerializer < ActiveModel::Serializer
  attributes :id, :name, :priority
  attribute :appliance_set_type
end