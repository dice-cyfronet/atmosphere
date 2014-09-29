# This class is used to populate the Atmosphere database with information regarding the available virtual machine flavors for each compute site
class FlavorManager

  # Scan each ComputeSite and update the Atmosphere database as needed
  def self.scan_all_sites
    ComputeSite.all.each do |cs|
      Rails.logger.info("Updating virtual machine flavors for cloud site #{cs.id}.")
      self.scan_site(cs)
    end
  end

  def self.scan_site(cs)
    begin
      # Purge flavors which no longer exist in cs
      existing_flavors = cs.cloud_client.flavors.collect{|f| f.id}
      cs.virtual_machine_flavors.each do |flavor|
        if !(existing_flavors.include? flavor.id_at_site) and flavor.virtual_machines.count == 0
          flavor.destroy
        end
      end

      # Retrieve the current list of flavors from cs and update Atmo representation accordingly
      cs.cloud_client.flavors.each do |flavor|
        self.check_and_update_flavor(cs, flavor)
      end
    rescue Exception => e
      Rails.logger.error("Unable to update flavors for cloud site #{cs.id}: #{e.message}. Skipping.")
    end
  end

  # Upserts the selected flavor in the selected cloud site. If this flavor is already defined for this cloud site, its parameters are updated.
  # Otherwise a new record is created with hourly cost = 0.
  def self.check_and_update_flavor(cs, flavor)
    # Check if this flavor is already defined for cs. Assuming that the flavor is uniquely identified by its id_at_site
    vm_flavor = cs.virtual_machine_flavors.find_or_initialize_by(id_at_site: flavor.id.to_s)
    vm_flavor.flavor_name = flavor.name
    vm_flavor.cpu = flavor.vcpus
    vm_flavor.memory = flavor.ram
    vm_flavor.hdd = flavor.disk
    vm_flavor.supported_architectures = flavor.supported_architectures
    vm_flavor.hourly_cost = 0 if vm_flavor.new_record?

    unless vm_flavor.save
      Rails.logger.error("Unable to save vm flavor with name #{vm_flavor.name}: nested exception is #{vm_flavor.errors}")
    end
  end

  # Checks if the flavor with a given ID is defined in compute site cs
  def self.exists_in_compute_site? (cs, flavor_id)
    cs.cloud_client.flavors.select{|f| f.id.to_s == flavor_id.to_s}.count > 0
  end
end