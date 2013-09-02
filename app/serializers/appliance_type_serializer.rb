class ApplianceTypeSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :description, :shared, :scalable, :visibility

  has_one :author, key: :author

  has_many :appliances, :port_mapping_templates, :appliance_configuration_templates, :virtual_machine_templates
end
