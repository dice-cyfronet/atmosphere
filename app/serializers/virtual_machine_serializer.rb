#
# Virtual machine serializer.
#
class VirtualMachineSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :id_at_site, :name, :state, :ip, :flavor_id
  has_one :compute_site

  def flavor_id
    object.virtual_machine_flavor_id
  end
end
