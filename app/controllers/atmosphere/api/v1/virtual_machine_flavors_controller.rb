module Atmosphere
  module Api
    module V1
      class VirtualMachineFlavorsController < Atmosphere::Api::ApplicationController
        authorize_resource :virtual_machine_flavor,
          class: 'Atmosphere::VirtualMachineFlavor'

        respond_to :json
        before_filter :validate_params!,
                      :validate_filter_combination!, only: :index

        # Query params may include either:
        # - appliance_configuration_instance_id and optionally compute_site_id
        # - appliance_type_id and optionally compute_site_id
        # - a combination of compute_site_id, cpu, memory, hdd
        # or be empty.
        def index
          flavors = []
          cs_id = params[:compute_site_id]

          if optimizer_query?
            tmpls = VirtualMachineTemplate.
              active.
              on_active_tenant.
              includes(
                tenants: [
                  virtual_machine_flavors: [
                    :os_families, :flavor_os_families
                  ]
                ]
              )
              .where(appliance_type_id: appl_type_id)
            tmpls = tmpls.on_tenant(cs_id) if cs_id

            unless tmpls.blank?
              _, _, flavor, _ = Optimizer.instance
                .select_tmpl_and_flavor_and_tenant(tmpls, nil, params)

              flavors = [flavor]
            end
          else
            flavors = VirtualMachineFlavor.with_prefs(params).where(filter)
            flavors = flavors.on_tenant(cs_id) if cs_id
          end
          flavors = flavors.first(limit) if limit

          respond_with flavors
        end

        private

        def filter
          filter = super
          filter.reject!{ |k,v| [:cpu, :memory, :hdd].include?(k) }
          filter
        end

        def appl_type_id
          appliance_type_id || at_id_for_config_inst
        end

        def at_id_for_config_inst
          config_tmpl = ApplianceConfigurationTemplate.
            with_config_instance(config_instance_id)

          config_tmpl.appliance_type_id
        end

        def validate_params!
          allowed_query_params.each do |param_name|
            if invalid_number_param?(params[param_name])
              raise Atmosphere::InvalidParameterFormat.new(
                "Invalid parameter format for #{param_name}")
            end
          end
        end

        def allowed_query_params
          [
            'appliance_configuration_instance_id',
            'appliance_type_id','compute_site_id',
            'cpu', 'memory', 'hdd'
          ]
        end

        def validate_filter_combination!
          raise Atmosphere::Conflict,
            "Illegal combination of filters" if conflicted_queries?
        end

        def conflicted_queries?
          appliance_type_id && config_instance_id
        end

        def optimizer_query?
          appliance_type_id || config_instance_id
        end

        def config_instance_id
          params[:appliance_configuration_instance_id]
        end

        def appliance_type_id
          params[:appliance_type_id]
        end

        def limit
          if params[:limit] && (l = params[:limit].to_i) > 0
            l
          end
        end

        def invalid_number_param?(nr)
          nr && !(nr =~ /\A^\d+$\z/)
        rescue ArgumentError => e
          logger.error("Unable to parse param value: #{e.message}")
          true
        end

        def model_class
          Atmosphere::VirtualMachineFlavor
        end
      end
    end
  end
end
