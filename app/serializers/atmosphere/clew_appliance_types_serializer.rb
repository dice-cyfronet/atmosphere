module Atmosphere
  class ClewApplianceTypesSerializer < ActiveModel::Serializer

    attribute :appliance_types

    attribute :tenants

    def appliance_types
      object[:appliance_types].map { |at| map_at(at) }
    end

    def map_at(at)
      flavor = selected_flavor_for(at)
      {
        id: at.id,
        name: at.name,
        description: at.description,
        preference_cpu: at.preference_cpu,
        preference_memory: at.preference_memory,
        preference_disk: at.preference_disk,
        matched_flavor: map_flavor(flavor),
        tenant_ids: at.tenant_ids,
        appliance_configuration_templates: at.appliance_configuration_templates
      }
    end

    def tenants
      tenants = {}
      object[:appliance_types].each do |at|
        at.tenants.each do |t|
          tenants[t.id] ||= t
        end
      end
      tenants.values.map { |t| map_t(t) }
    end

    def map_flavor(flavor)
      {
        id: flavor.id,
        flavor_name: flavor.flavor_name,
        cpu: flavor.cpu,
        memory: flavor.memory,
        hdd: flavor.hdd,
        tenant_id: flavor.tenant_id,
        id_at_site: flavor.id_at_site,
        supported_architectures: flavor.supported_architectures,
        active: flavor.active,
        hourly_cost: flavor.hourly_cost,
        cost_map: flavor.cost_map
      }
    end

    def map_t(t)
      {
        id: t.id,
        tenant_id: t.tenant_id,
        name: t.name,
        location: t.location,
        tenant_type: t.tenant_type,
        technology: t.technology,
        http_proxy_url: t.http_proxy_url,
        https_proxy_url: t.https_proxy_url,
        config: "SANITIZED",
        template_filters: t.template_filters,
        active: t.active
      }
    end

    # TEMPORARY SOLITION - PLEASE FIX!!!!!!!!!!!!!!!!!!!!!!!!
    def  selected_flavor_for(at)
      params = {}
      params[:cpu] &&= at.preference_cpu
      params[:memory] &&= at.preference_memory
      params[:hdd] &&= at.preference_disk

      tmpls = VirtualMachineTemplate.active.on_active_cs
        .where(appliance_type_id: at.id)
      flavor = nil

      unless tmpls.blank?
        _, flavor = Optimizer.instance
          .select_tmpl_and_flavor(tmpls, params)
      end

      flavor
    end
  end
end
