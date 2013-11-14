class ApplianceTypeSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :description, :shared, :scalable, :visible_for
  attributes :preference_cpu, :preference_memory, :preference_disk

  has_one :author
  has_one :security_proxy

  has_many :appliances, :port_mapping_templates, :appliance_configuration_templates, :virtual_machine_templates
end
