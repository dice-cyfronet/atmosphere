class VirtualMachineFlavorSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :flavor_name,
    :cpu, :memory, :hdd, :hourly_cost,
    :compute_site_id, :id_at_site,
    :supported_architectures, :active

  def active
    object.active?
  end
end