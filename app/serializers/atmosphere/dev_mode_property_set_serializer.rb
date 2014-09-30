#
# Dev mode property set serializer.
#
module Atmosphere
  class DevModePropertySetSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :name, :description, :shared, :scalable
    attributes :preference_cpu, :preference_memory, :preference_disk

    has_one :appliance, :security_proxy
    has_many :port_mapping_templates
  end
end
