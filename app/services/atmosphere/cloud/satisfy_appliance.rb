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
            appl_manager.reuse_vm!(vm)
            action.log(I18n.t('satisfy_appliance.reused', vm: vm.id_at_site))
          else
            new_vms_tmpls_and_flavors.each do |tmpl_and_flavor|
              tmpl = tmpl_and_flavor[:template]
              flavor = tmpl_and_flavor[:flavor]
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
              else
                action.log(I18n.t('satisfy_appliance.starting_vm',
                                  tmpl: tmpl.id_at_site,
                                  flavor: flavor.id_at_site))
                appl_manager.spawn_vm!(tmpl, flavor, vm_name)
                action.log(I18n.t('satisfy_appliance.vm_started',
                                  tmpl: tmpl.id_at_site,
                                  flavor: flavor.id_at_site))
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

      def new_vms_tmpls_and_flavors
        optimization_strategy.new_vms_tmpls_and_flavors
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
