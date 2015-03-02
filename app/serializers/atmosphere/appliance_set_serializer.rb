#
# Appliance set serializer.
#
module Atmosphere
  class ApplianceSetSerializer < ActiveModel::Serializer
    include Atmosphere::ApplianceSetSerializerExt
    attributes :id, :name, :priority
    attribute :appliance_set_type
  end
end