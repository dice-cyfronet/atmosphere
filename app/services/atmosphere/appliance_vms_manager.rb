#
# Manager for starting and reusing VM for specified appliance.
#
module Atmosphere
  class ApplianceVmsManager
    def initialize(appliance,
        updater_class = Proxy::ApplianceProxyUpdater,
        vm_creator_class = Cloud::VmCreator,
        tags_manager_class = Cloud::VmTagsManager)
      @appliance = appliance
      @updater = updater_class.new(appliance)
      @vm_creator_class = vm_creator_class
      @tags_manager = tags_manager_class.new
    end

    def reuse_vm!(vm)
      if BillingService.can_afford_vm?(appliance, vm)
        add_vm(vm)
      else
        not_enough_funds
      end
    end

    def spawn_vm!(tmpl, flavor, name)
      if BillingService.can_afford_flavor?(appliance, flavor)
        instantiate_vm(tmpl, flavor, name)
      else
        not_enough_funds
      end
    end

    def save
      appliance.save.tap { |saved| bill if saved }
    end

    private

    attr_reader :appliance, :updater

    def not_enough_funds
      unsatisfied('Not enough funds')
      appliance.billing_state = 'expired'
    end

    def unsatisfied(msg)
      appliance.state = :unsatisfied
      appliance.state_explanation = msg
    end

    def instantiate_vm(tmpl, flavor, name)
      server_id = start_vm_on_cloud(tmpl, flavor, name)
      if defined? Air.config.ostnic
        nic = Air.config.ostnic.nic
      else
        nic = ''
      end
      vm = appliance.virtual_machines.create(
          name: name, source_template: tmpl,
          state: :build, virtual_machine_flavor: flavor,
          managed_by_atmosphere: true, id_at_site: server_id,
          compute_site: tmpl.compute_site,
          nic: nic
        )

      if vm.valid?
        appliance_satisfied(vm)
      else
        unsatisfied('Unable to assign VM to appliance - please contact administrator')
        Raven.capture_message('Unable to assign VM to appliance',
            logger: 'error',
            extra: {
              is_at_site: server_id,
              appliance_name: appliance.name,
              appliance_id: appliance.id,
              errors: vm.errors.to_json
            }
          )
      end
    end

    def start_vm_on_cloud(tmpl, flavor, name)


      @vm_creator_class.new(
          tmpl,
          flavor: flavor, name: name,
          user_data: appliance.user_data,
          user_key: appliance.user_key
        ).spawn_vm!
    end

    def add_vm(vm)
      appliance.virtual_machines << vm
      appliance_satisfied(vm)
    end

    def appliance_satisfied(vm)
      appliance.state = :satisfied
      updater.update(new_vm: vm)
      @tags_manager.create_tags_for_vm(vm)
    end

    def bill
      BillingService.bill_appliance(
          appliance,
          Time.now.utc,
          'Optimization completed - performing billing action.',
          true
        ) if appliance.state.satisfied?
    end
  end
end
