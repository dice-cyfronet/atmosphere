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
    attributes :compute_site_ids

    has_many :appliances, :port_mapping_templates,
             :appliance_configuration_templates,
             :virtual_machine_templates

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

    def compute_site_ids
      ts = object.tenants.active
      unless options[:load_all?]
        ts = ts.where(id: scope.tenants)
      end
      ts.pluck(:id)
    end
  end
end
