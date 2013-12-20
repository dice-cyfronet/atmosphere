class ApplianceTypeSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :description, :shared, :scalable, :visible_to
  attributes :preference_cpu, :preference_memory, :preference_disk
  attributes :active

  has_one :author
  has_one :security_proxy

  has_many :appliances, :port_mapping_templates, :appliance_configuration_templates, :virtual_machine_templates

  def active
    object.virtual_machine_templates.where(state: :active).count > 0
  end

  # visible_for will be removed after update MI will be deployed
  attributes :visible_for
  def visible_for
    visible_to
  end
end
