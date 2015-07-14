#
# Virtual machine template serializer.
#
module Atmosphere
  class VirtualMachineTemplateSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :compute_site_id, :id_at_site, :name, :state,
               :managed_by_atmosphere, :architecture

    has_one :appliance_type

    def compute_site_id
      ts = object.tenants.active
      unless options[:load_all?]
        ts = ts & current_user.tenants
      end
      ts.blank? ? nil : ts.first.id
    end
  end
end
