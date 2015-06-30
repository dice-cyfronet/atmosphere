#
# Appliance serializer.
#
module Atmosphere
  class ApplianceSerializer < ActiveModel::Serializer
    include Atmosphere::ApplianceSerializerExt
    embed :ids

    attributes :id, :name, :description, :state, :state_explanation, :amount_billed, :prepaid_until
    has_one :appliance_configuration_instance, :appliance_set, :appliance_type
    has_many :tenants, :virtual_machines
  end
end