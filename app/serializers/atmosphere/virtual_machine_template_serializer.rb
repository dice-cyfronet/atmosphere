#
# Virtual machine template serializer.
#
module Atmosphere
  class VirtualMachineTemplateSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :id_at_site, :name, :state,
               :managed_by_atmosphere, :architecture

    has_one :compute_site, :appliance_type
  end
end
