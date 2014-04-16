# This migration creates a link between Appliance and ComputeSite
# The purpose is to restrict the spawning of VMs to specific sites, selected by the user

class BindAppliancesToComputeSites < ActiveRecord::Migration
  def change
    create_table :appliance_compute_sites do |t|
      t.belongs_to :appliance
      t.belongs_to :compute_site
    end

    # Retroactively update all Appliances
    Appliance.all.each do |a|
      a.compute_sites = ComputeSite.all
      a.save
    end
  end
end
