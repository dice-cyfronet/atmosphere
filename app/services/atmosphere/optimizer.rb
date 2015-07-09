module Atmosphere
  class Optimizer
    include Singleton

    # Runs optimization of resource allocation (i.e. virtual machines in cloud).
    # If hint is provided it is used to narrow the scope of optimization.
    # Hint can be provided in a hash with one of the following keys:
    # :appliance_id DB id of the appliance that was created. Optimization only akes care of finding a vm or creating a new one for given appliance.
    def run(hint)
      satisfy_appliance(hint[:created_appliance]) if hint[:created_appliance]
    end

    #private
    def satisfy_appliance(appliance)
      Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute
    end

    def select_tmpl_and_flavor_and_tenant(tmpls, appliance=nil, options={})
      tmpl_and_flavor_and_tenant = select_tmpls_and_flavors_and_tenants(tmpls, appliance, options).first
      [tmpl_and_flavor_and_tenant[:template], tmpl_and_flavor_and_tenant[:tenant],
        tmpl_and_flavor_and_tenant[:flavor]]
    end

    def select_tmpls_and_flavors_and_tenants(tmpls, appliance=nil, options={})
      OptimizationStrategy::Default.select_tmpls_and_flavors_and_tenants(tmpls, appliance, options)
    end
  end
end
