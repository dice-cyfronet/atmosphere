module Api
  module V1

    class VirtualMachineFlavorsController < Api::ApplicationController
      authorize_resource :virtual_machine_flavor
      respond_to :json

      # Query params may include either:
      # - appliance_configuration_instance_id and optionally compute_site_id
      # - appliance_type_id and optionally compute_site_id
      # - a combination of compute_site_id, cpu, memory, hdd
      # or be empty.
      def index
        validate_params
        @virtual_machine_flavors = []
        if filters_empty? || requirements_filters?
          conditions_str = build_condition_str
          @virtual_machine_flavors = VirtualMachineFlavor.where(conditions_str, params)
        elsif appliance_type_filters? || appliance_conf_inst_filters?
          appl_type_id = params['appliance_type_id'] || get_appl_type_id_for_config_inst()

          tmpls = VirtualMachineTemplate.active.on_active_cs
            .where(appliance_type_id: appl_type_id)

          tmpls = tmpls.where(compute_site_id: params['compute_site_id']) if
            params['compute_site_id']

          options = {}
          options[:preference_memory] = params['memory'].to_i if params['memory']
          options[:preference_cpu] = params['cpu'].to_i if params['cpu']
          options[:preference_disk] = params['hdd'].to_i if params['hdd']
          unless tmpls.blank?
            tmpl, flavor = Optimizer.instance.select_tmpl_and_flavor(tmpls, options)
            @virtual_machine_flavors = [flavor]
          end
        else
          raise Air::Conflict.new("Illegal combination of filters")
        end
        if params['limit']
          limit = params['limit'].to_i
          if limit >= 1
            @virtual_machine_flavors = @virtual_machine_flavors.first(limit)
          end
        end
        respond_with @virtual_machine_flavors
      end

      private
      def build_condition_str
        cs_condition = params['compute_site_id'] ? "compute_site_id = :compute_site_id" : ''
        cpu_condition = params['cpu'] ? "cpu >= :cpu" : ''
        mem_condition = params['memory'] ? "memory >= :memory" : ''
        hdd_condition = params['hdd'] ? "hdd >= :hdd" : ''
        [cs_condition, cpu_condition, mem_condition, hdd_condition].reject{|e| e.blank?}.join(" AND ")
      end

      def get_appl_type_id_for_config_inst()
        config_inst = ApplianceConfigurationInstance.find(params['appliance_configuration_instance_id'])
        config_tmpl = config_inst.appliance_configuration_template
        if config_tmpl.nil?
          raise ActiveRecord::RecordNotFound
        end
        config_tmpl.appliance_type_id
      end

      def filters_empty?
        (params.keys & ['appliance_configuration_instance_id', 'appliance_type_id','compute_site_id', 'cpu', 'memory', 'hdd']).empty?
      end

      def appliance_conf_inst_filters?
        keys = params.keys
        (keys.include? 'appliance_configuration_instance_id') && (keys & ['appliance_type_id']).empty?
      end

      def appliance_type_filters?
        keys = params.keys
        (keys.include? 'appliance_type_id') && (keys & ['appliance_configuration_instance_id']).empty?
      end

      def requirements_filters?
        keys = params.keys
        (not (keys & ['compute_site_id', 'cpu', 'memory', 'hdd']).empty?) && (keys & ['appliance_configuration_instance_id', 'appliance_type_id']).empty?
      end

      def validate_params
        possitive_number_re = /^\d+$/
        ['hdd', 'memory', 'cpu', 'compute_site_id', 'appliance_type_id', 'appliance_configuration_instance_id'].each do |param_name|
          if params[param_name] && !(params[param_name] =~ possitive_number_re)
            raise Air::InvalidParameterFormat.new("Invalid parameter format for #{param_name}")
          end
        end
      end

    end

  end
end