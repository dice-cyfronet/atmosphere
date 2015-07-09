#
# Manager for starting and reusing VM for specified appliance.
#
module Atmosphere
  class ApplianceVmsManager

    include Atmosphere::ApplianceVmsManagerExt

    def initialize(appliance,
        updater_class = Proxy::ApplianceProxyUpdater,
        vm_creator_class = Cloud::VmCreator,
        tags_manager_class = Cloud::VmTagsManager)
      @appliance = appliance
      @updater = updater_class.new(appliance)
      @vm_creator_class = vm_creator_class
      @tags_manager_class = tags_manager_class
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

    def start_vms!(vms_descs)
      if BillingService.can_afford_flavors?(appliance, vms_descs.map{ |desc| desc[:flavor]})
        vms_descs.each { |desc| instantiate_vm(desc[:template], desc[:flavor], desc[:name]) }
      else
        unsatisfied('Not enough funds to scale')
      end
    end

    def stop_vms!(vms_to_stop)
      vms_to_stop.each { |vm| Cloud::VmDestroyWorker.perform_async(vm.id) }
    end

    def save
      appliance.save.tap { |saved| bill if saved }
    end

    def unsatisfied(msg)
      appliance.state = :unsatisfied
      appliance.state_explanation = msg
    end

    private

    attr_reader :appliance, :updater

    def not_enough_funds
      unsatisfied('Not enough funds')
    end

    def instantiate_vm(tmpl, flavor, name)
      server_id = start_vm_on_cloud(tmpl, flavor, name)
      # TODO It is CRITICALLY IMPORTANT to replace this tenant assignment with one referring
      # to the current user of @appliance (needs a suitable method/attribute in Atmosphere::User).
      vm = VirtualMachine.find_or_initialize_by(
          id_at_site: server_id,
          tenant: tmpl.tenants.first
        )
      vm.name = name
      vm.source_template = tmpl
      vm.state = :build
      vm.virtual_machine_flavor = flavor
      vm.managed_by_atmosphere = true
      appliance.virtual_machines << vm

      vm.save

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
      # WARNING: this will not work properly in deployments which restrict users to tenants.
      # (More specifically, it will use a semi-random cloud client and network ID
      # to launch the VM as the Atmosphere engine has no concept of "desired tenant".)
      # This method should be overridden in any subproject which makes use of tenants.
      nic = Atmosphere.nic_provider(tmpl.tenants.first).get(@appliance)
      if nic.present?
        Rails.logger.info("Using custom NIC: #{nic}")
      else
        Rails.logger.info('Using default NIC.')
      end

      # TODO It is CRITICALLY IMPORTANT to replace this tenant assignment with one referring
      # to the current user of @appliance (needs a suitable method/attribute in Atmosphere::User).
      @vm_creator_class.new(
          tmpl,
          tenant: tmpl.tenants.first,
          flavor: flavor,
          name: name,
          user_data: appliance.user_data,
          user_key: appliance.user_key,
          nic: nic
        ).execute
    end

    def add_vm(vm)
      appliance.virtual_machines << vm
      appliance_satisfied(vm)
    end

    def appliance_satisfied(vm)
      appliance.state = :satisfied
      updater.update(new_vm: vm)
      @tags_manager_class.new(vm).execute
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
