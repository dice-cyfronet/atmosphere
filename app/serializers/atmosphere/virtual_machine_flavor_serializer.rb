module Atmosphere
  class VirtualMachineFlavorSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :flavor_name,
      :cpu, :memory, :hdd, :hourly_cost,
      :tenant_id, :id_at_site,
      :supported_architectures, :active, :cost_map

    private

    # Returns a full cost map for this flavor (depending on os_family)

    def active
      object.usable?
    end
  end
end