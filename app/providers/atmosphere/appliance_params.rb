module Atmosphere
  class ApplianceParams
    def initialize(params, allowed_params_ext, delegated_auth)
      @params = params
      @allowed_params_ext = allowed_params_ext
      @delegated_auth = delegated_auth
    end

    def create_params
      (development? ? dev_params : prod_params).tap do |p|
        at = config_template.appliance_type

        p[:appliance_type_id] = at.id
        p[:name] ||= at.name
        p[:description] ||= at.description
        p[:tenants] = allowed_tenants
      end
    end

    def dev_mode_params
      if development?
        prefs = params.permit(dev_mode_property_set: [
                                :preference_memory,
                                :preference_cpu,
                                :preference_disk])
        prefs[:dev_mode_property_set] || {}
      end
    end

    def config_params
      (params[:params] || {}).tap do |p|
        if Atmosphere.delegation_initconf_key
          p[Atmosphere.delegation_initconf_key] = delegated_auth
        end
      end
    end

    def config_template
      @config_template ||=
        ApplianceConfigurationTemplate.find(config_template_id)
    end

    private

    attr_reader :params, :allowed_params_ext, :delegated_auth

    def appliance_set
      @appliance_set ||= ApplianceSet.find(appliance_set_id)
    end

    def prod_params
      params.permit(basic_allowed_params + allowed_params_ext).to_h.tap do |p|
        p[:optimization_policy_params] = { vms: params[:vms] }
      end
    end

    def appliance_set_id
      params.permit(:appliance_set_id)[:appliance_set_id]
    end

    def dev_params
      params.permit(basic_allowed_params + [:user_key_id] + allowed_params_ext)
    end

    def basic_allowed_params
      [:appliance_set_id, :name, :description, :tenant_ids]
    end

    def config_template_id
      params[:configuration_template_id]
    end

    def allowed_tenants
      if params[:tenant_ids].blank?
        Tenant.active
      else
        Tenant.where(id: params[:tenant_ids], active: true)
      end
    end

    def development?
      appliance_set.development?
    end
  end
end
