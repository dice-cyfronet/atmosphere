#
# Appliance type serializer.
#
module Atmosphere
  class ApplianceTypeSerializer < ActiveModel::Serializer
    include Atmosphere::ApplianceTypeSerializerExt
    embed :ids

    attributes :id, :name, :description, :shared, :scalable, :visible_to, :author_id
    attributes :preference_cpu, :preference_memory, :preference_disk
    attributes :active, :saving

    has_many :appliances, :port_mapping_templates, :appliance_configuration_templates, :virtual_machine_templates, :compute_sites

    def author_id
      object.user_id
    end

    def active
      active_vmts = object.virtual_machine_templates
      .joins(:compute_site)
      .where(state: :active, atmosphere_compute_sites: { active: true })

      active_vmts.count > 0
    end

    def saving
      saving_vms = object.virtual_machine_templates
      .where(state: :saving)

      saving_vms.count > 0
    end


    def compute_sites
      object.compute_sites.active
    end
  end
end