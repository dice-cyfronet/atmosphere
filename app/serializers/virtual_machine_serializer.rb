class VirtualMachineSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :id_at_site, :name, :state, :ip
  has_one :compute_site
end