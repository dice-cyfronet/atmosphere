#
# Appliance set serializer.
#
module Atmosphere
  class ApplianceSetSerializer < ActiveModel::Serializer
    attributes :id, :name, :priority, :optimization_policy
    attribute :appliance_set_type
  end
end