# This class is used to populate the Atmosphere database with information regarding the available virtual machine flavors for each compute site
module Atmosphere
  class FlavorManager

    # Scan each Tenant and update the Atmosphere database as needed
    def self.scan_all_tenants
      Tenant.all.each do |t|
        Rails.logger.info("Updating virtual machine flavors for tenant #{t.id}.")
        self.scan_tenant(t)
      end
    end

    def self.scan_tenant(t)
      begin
        # Purge flavors which no longer exist in tenant
        existing_flavors = t.cloud_client.flavors.collect{|f| f.id}
        t.virtual_machine_flavors.each do |flavor|
          if !(existing_flavors.include? flavor.id_at_site) and flavor.virtual_machines.count == 0
            flavor.destroy
          end
        end

        # Retrieve the current list of flavors from t and update Atmo representation accordingly
        t.cloud_client.flavors.each do |flavor|
          self.check_and_update_flavor(t, flavor)
        end
      rescue Exception => e
        Rails.logger.error("Unable to update flavors for tenant #{t.id}: #{e.message}. Skipping.")
      end
    end

    # Upserts the selected flavor in the selected tenant. If this flavor is already defined for this tenant, its parameters are updated.
    # Otherwise a new record is created with hourly cost = 0.
    def self.check_and_update_flavor(t, flavor)
      # Check if this flavor is already defined for t. Assuming that the flavor is uniquely identified by its id_at_site
      vm_flavor = t.virtual_machine_flavors.find_or_initialize_by(id_at_site: flavor.id.to_s)
      vm_flavor.flavor_name = flavor.name
      vm_flavor.cpu = flavor.vcpus
      vm_flavor.memory = flavor.ram
      vm_flavor.hdd = flavor.disk
      vm_flavor.supported_architectures = flavor.supported_architectures

      unless vm_flavor.save
        Rails.logger.error("Unable to save vm flavor with name #{vm_flavor.flavor_name}: nested exception is #{vm_flavor.errors}")
      end
    end

    # Checks if the flavor with a given ID is defined in tenant t
    def self.exists_in_tenant? (t, flavor_id)
      t.cloud_client.flavors.select{|f| f.id.to_s == flavor_id.to_s}.count > 0
    end
  end
end