#
# Virtual machine serializer.
#
module Atmosphere
  class VirtualMachineSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :id_at_site, :name, :state, :ip, :virtual_machine_flavor_id
    has_one :tenant, key: :compute_site_id
  end
end
