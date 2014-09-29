#
# Appliance serializer.
#
class ApplianceSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :description, :state, :state_explanation, :amount_billed, :prepaid_until
  has_one :appliance_configuration_instance, :appliance_set, :appliance_type
  has_many :compute_sites, :virtual_machines
end
