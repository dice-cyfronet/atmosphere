#
# Appliance configuration template serializer.
#
module Atmosphere
  class ApplianceConfigurationTemplateSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :name, :payload, :parameters
    has_one :appliance_type
  end
end
