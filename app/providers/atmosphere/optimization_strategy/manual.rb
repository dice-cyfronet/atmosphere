module Atmosphere
  module OptimizationStrategy
    class Manual < OptimizationStrategy::Default
      attr_reader :appliance

      def initialize(appliance)
        @appliance = appliance
      end

      def can_reuse_vm?
        false
      end

      def vm_to_reuse
        nil
      end

      def new_vms_tmpls_and_flavors_and_tenants
        tmpls_and_flavors_and_tenants = []
        tmpls = vmt_candidates
        appliance.optimization_policy_params['vms'].each do |vm|
          options = {cpu: vm['cpu'], memory: vm['mem']}
          tmpls_and_flavors_and_tenants += Default.select_tmpls_and_flavors_and_tenants(tmpls, @appliance, options)
        end
        tmpls_and_flavors_and_tenants
      end

      def can_scale_manually?
        true
      end

      def vms_to_stop(quantity)
        appliance.active_vms.last(quantity)
      end

      def vms_to_start(quantity)
        source_vm = appliance.active_vms.first

        [{ template: source_vm.source_template,
           tenant: source_vm.tenant,
           flavor: source_vm.virtual_machine_flavor,
           name: source_vm.name }] * quantity
      end
    end
  end
end
