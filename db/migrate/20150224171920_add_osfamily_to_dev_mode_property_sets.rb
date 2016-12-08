# This migration adds a reference to OSFamily in DevModePropertySet
# This is required in order to automatically assign OSFamilies to any new AT.

class AddOsfamilyToDevModePropertySets < ActiveRecord::Migration[4.2]
  def up
    add_reference :atmosphere_dev_mode_property_sets, :os_family

    # Rewrite all existing DMPSs to use the 'windows' OS (correct later as necessary)
    Atmosphere::DevModePropertySet.find_each do |dmps|
      dmps.os_family = Atmosphere::OSFamily.first
      dmps.save
    end
  end

  def down
    remove_column :atmosphere_dev_mode_property_sets, :os_family_id
  end
end
