module Atmosphere
  class ClewApplianceTypesSerializer < ActiveModel::Serializer

    attribute :appliance_types

    attribute :tenants, key: :compute_sites

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
        compute_site_ids: at.tenant_ids & current_user.tenants.map(&:id),
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
        compute_site_id: flavor.tenant_id,
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
        site_id: t.tenant_id,
        name: t.name,
        location: t.location,
        site_type: t.tenant_type,
        technology: t.technology,
        http_proxy_url: t.http_proxy_url,
        https_proxy_url: t.https_proxy_url,
        config: "SANITIZED",
        template_filters: t.template_filters,
        active: t.active
      }
    end

    # TODO: This method attempts to find an optimal flavor for a given AT
    # However, flavor selection logic is predicated on the tenant(s) assigned to an appliance
    # No Appliance object exists at the time this method is invoked.
    # Actual price charged for Appliance MAY be higher than what is reported here, depending
    # on the user's Tenant selection. This should be fixed at a later date.
    def  selected_flavor_for(at)
      params = {}
      params[:cpu] &&= at.preference_cpu
      params[:memory] &&= at.preference_memory
      params[:hdd] &&= at.preference_disk

      tmpls = VirtualMachineTemplate.active.on_active_tenant
        .where(appliance_type_id: at.id)
      flavor = nil

      unless tmpls.blank?
          _, _, flavor, _ = Optimizer.instance
          .select_tmpl_and_flavor_and_tenant(tmpls, nil, params)
      end

      flavor
    end
  end
end
