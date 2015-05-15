module Atmosphere
  class Optimizer
    include Singleton

    # Runs optimization of resource allocation (i.e. virtual machines in cloud).
    # If hint is provided it is used to narrow the scope of optimization.
    # Hint can be provided in a hash with one of the following keys:
    # :appliance_id DB id of the appliance that was created. Optimization only akes care of finding a vm or creating a new one for given appliance.
    def run(hint)
      satisfy_appliance(hint[:created_appliance]) if hint[:created_appliance]
      terminate_unused_vms if hint[:destroyed_appliance]
    end

    #private
    def satisfy_appliance(appliance)
      Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute
    end

    def terminate_unused_vms
      Atmosphere::Cloud::DestroyUnusedVms.new.execute
    end

    def select_tmpl_and_flavor(tmpls, options={})
      tmpl_and_flavor = select_tmpls_and_flavors(tmpls, options).first
      [tmpl_and_flavor[:template], tmpl_and_flavor[:flavor]]
    end

    def select_tmpls_and_flavors(tmpls, options={})
      OptimizationStrategy::Default.select_tmpls_and_flavors(tmpls, options)
    end

    private

    def logger
      Atmosphere.optimizer_logger
    end
  end
end
