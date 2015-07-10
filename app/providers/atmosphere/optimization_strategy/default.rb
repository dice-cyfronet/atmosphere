require 'atmosphere/utils'

module Atmosphere
  module OptimizationStrategy
    class Default
      def initialize(appliance)
        @appliance = appliance
      end

      def self.select_tmpls_and_flavors_and_tenants(tmpls, appliance, options)
        VmtAndFlavorAndTenant.new(tmpls, appliance, options).select
      end

      def can_reuse_vm?
        !appliance.development? && appliance.appliance_type.shared
      end

      def vm_to_reuse
        VirtualMachine.reusable_by(appliance).select { |vm| reuse?(vm) }.first
      end

      def new_vms_tmpls_and_flavors_and_tenants
        tmpls = vmt_candidates_for(appliance)
        return [{template: nil, flavor: nil, tenant: nil}] if tmpls.blank?

        Default.select_tmpls_and_flavors_and_tenants(tmpls, appliance, preferences)
      end

      def can_scale_manually?
        false
      end

      protected

      def vmt_candidates_for(appliance)
        vmts = VirtualMachineTemplate.where(
          appliance_type: appliance.appliance_type,
          state: 'active'
        )
        if appliance.tenants.present?
          vmts = restrict_by_user_requirements(vmts, appliance)
        end
        restrict_by_tenant_availability(vmts, appliance)
      end

      private

      attr_reader :appliance

      # If the user requests that the appliance be bound to a specific set of tenants,
      # the optimizer should honor this selection. This method ensures that it happens.
      def restrict_by_user_requirements(vmts, appliance)
        funded_active_tenants = appliance.tenants.active.funded_by(appliance.fund)
        Atmosphere::VirtualMachineTemplate.joins(:tenants).
          where(Atmosphere::VirtualMachineTemplate.arel_table[:id].in(vmts.pluck(:id)).
          and(Atmosphere::Tenant.arel_table[:id].in(funded_active_tenants.pluck(:id))))
      end

      # In all cases the optimizer should only suggest those vmts which the user is able to access
      # (i.e. vmts which reside on at least one tenant which shares a fund with the appliance).
      def restrict_by_tenant_availability(vmts, appliance)
        Atmosphere::VirtualMachineTemplate.joins(:tenants).
          where(Atmosphere::VirtualMachineTemplate.arel_table[:id].in(vmts.pluck(:id)).
          and(Atmosphere::Tenant.arel_table[:id].in(appliance.fund.tenants.pluck(:id))))
      end

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

      class VmtAndFlavorAndTenant
        include Atmosphere::Utils

        def initialize(tmpls, appliance, options={})
          @tmpls = tmpls
          @appliance = appliance
          @options = options
        end

        # We are given a list of tmpls which MAY be spawned by the user in the context of @appliance.
        # We are asked to return a single template, a specific flavor and a specific tenant for instantiation.
        # Flavor prices may vary by tenant.
        # !CAUTION! @appliance can be nil -- this will happen when the method is invoked prior to
        # creation of an appliance.
        def select
          best_template = nil
          best_tenant = nil
          best_flavor = nil
          instantiation_cost = Float::INFINITY

          tmpls.each do |tmpl|
            candidate_tenants = get_candidate_tenants_for_template(tmpl)
            candidate_tenants.each do |t|
              opt_flavor, cost = get_optimal_flavor_for_tenant(tmpl, t)
              if cost < instantiation_cost
                best_template = tmpl
                best_tenant = t
                best_flavor = opt_flavor
                instantiation_cost = cost
              end
            end
          end

          # It is possible that nothing has been found - this would indicate unsatisfiable hardware requirements
          # (i.e. no flavor with sufficient CPU/memory/HDD) or non-existence of flavors supporting the selected
          # architecture.
          # If this occurs, return first template to avoid breaking user notification logic
          # in Atmosphere::Cloud::SatisfyAppliance
          # TODO: This is quite hacky; a better way to communicate errors to the user is needed.
          if best_template.blank?
            best_template = tmpls.first
          end

          [
            {
              template: best_template,
              tenant: best_tenant,
              flavor: best_flavor
            }
          ]
        end

        private

        attr_reader :tmpls, :options

        def get_candidate_tenants_for_template(tmpl)
          # Determine which tenants can be used to spawn this specific template in the context
          # of the current @appliance.
          # If @appliance is nil (which may happen) then return all of this tmpl's tenants:
          if @appliance.blank?
            # This will happen in pre-instantiation queries (such as in the CLEW
            # "Start application" window) where no appliance is yet present.
            tmpl.tenants
          else
            eligible_tenants = tmpl.tenants &
              @appliance.fund.tenants &
              @appliance.appliance_set.user.tenants

            if @appliance.tenants.present?
              # If appliance is manually restricted to a specific subset of tenants,
              # return intersection of eligible tenants and appliance tenants.
              eligible_tenants & @appliance.tenants
            else
              # Otherwise simply return all eligible tenants.
              eligible_tenants
            end
          end
        end

        def get_optimal_flavor_for_tenant(tmpl, t)
          opt_fl = (
          min_elements_by(
              t.virtual_machine_flavors.active.select do |f|
                f.supports_architecture?(tmpl.architecture) &&
                    f.memory >= min_mem &&
                    f.cpu >= min_cpu &&
                    f.hdd >= min_hdd
              end
          ) {|f| tmpl.get_hourly_cost_for(f) || Float::INFINITY }
          ).sort!{ |x,y| y.memory <=> x.memory }.last
          return opt_fl, opt_fl.present? ? tmpl.get_hourly_cost_for(opt_fl) : Float::INFINITY
        end

        def min_mem
          # TODO: Predicate default value on ComputeSite.public? once ComputeSite is reimplemented.
          @min_mem ||= to_i(options[:memory]) ||
            tmpls.first.appliance_type.preference_memory ||
            (tmpls.first.tenants.first.public? ? 1536 : 512)
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
