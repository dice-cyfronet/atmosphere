require 'atmosphere/utils'

module Atmosphere
  module OptimizationStrategy
    class Default
      def initialize(appliance)
        @appliance = appliance
      end

      def self.select_tmpls_and_flavors(tmpls, options)
        VmAndFlavor.new(tmpls, options).select
      end

      def can_reuse_vm?
        !appliance.development? && appliance.appliance_type.shared
      end

      def vm_to_reuse
        VirtualMachine.reusable_by(appliance).select { |vm| reuse?(vm) }.first
      end

      def new_vms_tmpls_and_flavors
        tmpls = vmt_candidates_for(appliance)
        return [{template: nil, flavor: nil}] if tmpls.blank?

        Default.select_tmpls_and_flavors(tmpls, preferences)
      end

      def can_scale_manually?
        false
      end

      protected

      def vmt_candidates_for(appliance)
        VirtualMachineTemplate.where(
          appliance_type: appliance.appliance_type,
          state: 'active',
          compute_site_id: appliance.compute_sites.active
        )
      end

      private

      attr_reader :appliance

      def reuse?(vm)
        vm.appliances.count < Atmosphere.optimizer.max_appl_no &&
        !vm.appliances.first.development?
      end

      def preferences
        props = appliance.dev_mode_property_set
        if props
          {
            cpu: props.preference_cpu,
            memory: props. preference_memory,
            hdd: props.preference_disk
          }
        else
          {}
        end
      end

      class VmAndFlavor
        include Atmosphere::Utils

        def initialize(tmpls, options={})
          @tmpls = tmpls
          @options = options
        end

        def select
          opt_flavors_and_tmpls_map = tmpls.inject({}) do |hsh, tmpl|
            opt_fl = (
              min_elements_by(
                tmpl.compute_site.virtual_machine_flavors.active.select do |f|
                  f.supports_architecture?(tmpl.architecture) &&
                  f.memory >= min_mem &&
                  f.cpu >= min_cpu &&
                  f.hdd >= min_hdd
                end
              ) {|f| tmpl.get_hourly_cost_for(f)}
            ).sort!{ |x,y| y.memory <=> x.memory }.last
            hsh[opt_fl] = tmpl if opt_fl
            hsh
          end

          globally_opt_flavor = (
            min_elements_by(
              opt_flavors_and_tmpls_map.keys
            ) { |f| tmpls.first.get_hourly_cost_for(f)}
          ).sort { |x,y| x.memory <=> y.memory }.last

          [
            {
              template: opt_flavors_and_tmpls_map[globally_opt_flavor] || tmpls.first,
              flavor: globally_opt_flavor
            }
          ]
        end

        private

        attr_reader :tmpls, :options

        def min_mem
          @min_mem ||= to_i(options[:memory]) ||
            tmpls.first.appliance_type.preference_memory ||
            (tmpls.first.compute_site.public? ? 1536 : 512)
        end

        def min_cpu
          @min_cpu ||= to_f(options[:cpu]) ||
            tmpls.first.appliance_type.preference_cpu || 1
        end

        def min_hdd
          @min_hdd ||= to_i(options[:hdd]) ||
            tmpls.first.appliance_type.preference_disk || 0
        end

        def to_i(obj)
          obj ? obj.to_i : nil
        end

        def to_f(obj)
          obj ? obj.to_f : nil
        end
      end
    end
  end
end