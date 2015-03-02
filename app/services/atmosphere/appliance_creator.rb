module Atmosphere
  class ApplianceCreator
    attr_reader :appliance

    def initialize(params, delegated_auth)
      @params = params
      @appliance = Appliance.new(create_params)
      @delegated_auth = delegated_auth
    end

    def build
      apply_preferences
      init_appliance_configuration

      appliance
    end

    private

    attr_reader :params, :delegated_auth

    def create_params
      c_params = development? ? dev_params : prod_params

      at = config_template.appliance_type

      c_params[:appliance_type_id] = at.id
      c_params[:name] ||= at.name
      c_params[:description] ||= at.description
      c_params[:compute_sites] = allowed_compute_sites

      c_params
    end

    def prod_params
      opt_policy_params = {}
      opt_policy_params[:vms] = params[:vms]

      allowed_params = [:appliance_set_id,
                        :name, :description,
                        :compute_site_ids] + allowed_params_ext
      prod_params = params.permit(allowed_params)
      prod_params[:optimization_policy_params] = opt_policy_params
      prod_params
    end

    def dev_params
      allowed_params = [:appliance_set_id,
                        :user_key_id,
                        :name, :description,
                        :compute_site_ids] + allowed_params_ext

      params.permit(allowed_params)
    end

    def allowed_compute_sites
      if params[:compute_site_ids].blank?
        ComputeSite.active
      else
        ComputeSite.where(id: params[:compute_site_ids], active: true)
      end
    end

    def apply_preferences
      appliance.create_dev_mode_property_set(preferences) if development?
    end

    def preferences
      prefs = params.permit(
                dev_mode_property_set: [
                  :preference_memory,
                  :preference_cpu,
                  :preference_disk
                ])
      prefs[:dev_mode_property_set] || {}
    end

    def init_appliance_configuration
      appliance.appliance_configuration_instance =
        ApplianceConfigurationInstance.get(config_template, config_params)
    end

    def development?
      appliance_set.development?
    end

    def appliance_set
      @appliance_set ||= ApplianceSet.find(appliance_set_id)
    end

    def appliance_set_id
      params.permit(:appliance_set_id)[:appliance_set_id]
    end

    def config_template
      @config_template ||=
        ApplianceConfigurationTemplate.find(config_template_id)
    end

    def config_template_id
      params[:configuration_template_id]
    end

    def config_params
      c_params = params[:params] || {}
      if Atmosphere.delegation_initconf_key
        c_params[Atmosphere.delegation_initconf_key] = delegated_auth
      end

      c_params
    end

    include Atmosphere::ApplianceCreatorExt
  end
end
