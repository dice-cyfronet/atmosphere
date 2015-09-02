module Atmosphere
  module Cloud
    class SatisfyAppliance

      def initialize(appliance)
        @appliance = appliance
      end

      def execute
        action.log(I18n.t('satisfy_appliance.start'))
        if appliance.virtual_machines.blank?
          if optimization_strategy.can_reuse_vm? &&
            !(vm = optimization_strategy.vm_to_reuse).nil?
            action.log(I18n.t('satisfy_appliance.reusing', vm: vm.id_at_site))
            # Assign correct fund for this VM to appliance
            appliance.fund ||= select_fund(appliance, vm.tenant)
            appl_manager.reuse_vm!(vm)
            action.log(I18n.t('satisfy_appliance.reused', vm: vm.id_at_site))
          else
            new_vms_tmpls_and_flavors_and_tenants.each do |tmpl_and_flavor_and_tenant|
              tmpl = tmpl_and_flavor_and_tenant[:template]
              flavor = tmpl_and_flavor_and_tenant[:flavor]
              tenant = tmpl_and_flavor_and_tenant[:tenant]
              if tmpl.blank?
                appliance.state = :unsatisfied
                appliance.state_explanation =
                  I18n.t('satisfy_appliance.no_tmpl')

                action.warn(appliance.state_explanation)
              elsif flavor.nil?
                appliance.state = :unsatisfied
                appliance.state_explanation =
                  I18n.t('satisfy_appliance.no_flavor')

                action.warn(appliance.state_explanation)
              elsif tenant.nil?
                appliance.state = :unsatisfied
                appliance.state_explanation =
                    I18n.t('satisfy_appliance.no_tenant')

                action.warn(appliance.state_explanation)
              else
                # Select fund to assign to appliance, if not yet assigned
                unless appliance.fund.present?
                  appliance.fund ||= select_fund(appliance, tenant)
                end

                action.log(I18n.t('satisfy_appliance.starting_vm',
                                  tmpl: tmpl.id_at_site,
                                  flavor: flavor.id_at_site))
                appl_manager.spawn_vm!(tmpl, tenant, flavor, vm_name)
                action.log(I18n.t('satisfy_appliance.vm_started',
                                  tmpl: tmpl.id_at_site,
                                  flavor: flavor.id_at_site,
                                  tenant: tenant.tenant_id))
              end
            end
          end
          unless appl_manager.save
            action.log(I18n.t('satisfy_appliance.error',
                              trace: appliance.errors.to_json))
          end
        end

        action.log(I18n.t('satisfy_appliance.end'))
      end

      private

      attr_reader :appliance

      def action
        unless @action
          @action = Action.create(appliance: appliance,
                                  action_type: :satisfy_appliance)
          @action.logger = logger
        end

        @action
      end

      def vm_name
        appliance.name.blank? ? appliance.appliance_type.name : appliance.name
      end

      def new_vms_tmpls_and_flavors_and_tenants
        optimization_strategy.new_vms_tmpls_and_flavors_and_tenants
      end

      def select_fund(appliance, tenant)
        cfs = tenant.funds & appliance.appliance_set.user.funds
        if cfs.include? appliance.appliance_set.user.default_fund
          appliance.appliance_set.user.default_fund
        elsif cfs.length > 0
          cfs.first
        end
      end

      def optimization_strategy
        @optimization_strategy ||= appliance.optimization_strategy
      end

      def appl_manager
        @appl_manager ||= ApplianceVmsManager.new(appliance)
      end

      def logger
        Atmosphere.optimizer_logger
      end
    end
  end
end
