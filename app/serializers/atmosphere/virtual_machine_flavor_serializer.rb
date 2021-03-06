module Atmosphere
  class VirtualMachineFlavorSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :flavor_name,
      :cpu, :memory, :hdd, :hourly_cost,
      :compute_site_id, :id_at_site,
      :supported_architectures, :active, :cost_map

    private

    def compute_site_id
      object.tenant_id
    end

    def active
      object.usable?
    end
  end
end
