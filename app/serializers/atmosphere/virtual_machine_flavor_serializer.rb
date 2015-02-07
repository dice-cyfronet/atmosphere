module Atmosphere
  class VirtualMachineFlavorSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :flavor_name,
      :cpu, :memory, :hdd, :hourly_cost,
      :compute_site_id, :id_at_site,
      :supported_architectures, :active, :cost_map

    private

    # Deprecated: returns max hourly cost
    def hourly_cost
      object.virtual_machine_flavor_os_families.max_by(&:hourly_cost).hourly_cost
    end

    # Returns a full cost map for this flavor (depending on os_family)
    def cost_map
      object.cost_map
    end

    def active
      object.usable?
    end
  end
end