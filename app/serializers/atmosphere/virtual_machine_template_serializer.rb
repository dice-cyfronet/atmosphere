#
# Virtual machine template serializer.
#
module Atmosphere
  class VirtualMachineTemplateSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :id_at_site, :name, :state,
               :managed_by_atmosphere, :architecture

    has_one :appliance_type
    has_one :tenant, key: :compute_site_id
  end
end
