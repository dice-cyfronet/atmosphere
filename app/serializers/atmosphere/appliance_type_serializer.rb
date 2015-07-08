#
# Appliance type serializer.
#
module Atmosphere
  class ApplianceTypeSerializer < ActiveModel::Serializer
    include Atmosphere::ApplianceTypeSerializerExt
    embed :ids

    attributes :id, :name, :description,
               :shared, :scalable, :visible_to, :author_id
    attributes :preference_cpu, :preference_memory, :preference_disk
    attributes :active, :saving

    has_many :appliances, :port_mapping_templates,
             :appliance_configuration_templates,
             :virtual_machine_templates

    has_many :tenants, key: :compute_site_ids

    private

    def author_id
      object.user_id
    end

    def active
      vmt_with_state?(:active)
    end

    def saving
      vmt_with_state?(:saving)
    end

    def vmt_with_state?(state)
      object.virtual_machine_templates.
        on_active_tenant.where(state: state).
          count > 0
    end

    def tenants
      object.tenants.active
    end
  end
end
