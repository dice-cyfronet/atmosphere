module Atmosphere
  module OptimizationStrategy
    class Manual < OptimizationStrategy::Default
      def initialize(appliance)
        @appliance = appliance
      end

      def can_reuse_vm?
        false
      end

      def vm_to_reuse
        nil
      end

      def new_vms_tmpls_and_flavors
        tmpls_and_flavors = []
        tmpls = vmt_candidates_for(@appliance)
        @appliance.optimization_policy_params['vms'].each do |vm|
          options = {cpu: vm['cpu'], memory: vm['mem']}
          tmpls_and_flavors += Default.select_tmpls_and_flavors(tmpls, options)
        end
        tmpls_and_flavors
      end

      def can_scale_manually?
        true
      end

      def vms_to_stop(appliance, quantity)
        appliance.active_vms.last(quantity)
      end

      def vms_to_start(appliance, quantity)
        source_vm = appliance.active_vms.first
        vms_to_stop = []
        quantity.times { vms_to_stop << {template: source_vm.source_template,
                                         flavor: source_vm.virtual_machine_flavor,
                                         name: source_vm.name} }
        vms_to_stop
      end
    end
  end
end
