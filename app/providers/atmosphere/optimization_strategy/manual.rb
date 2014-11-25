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

      def can_manually_scale?
        true
      end
    end
  end
end