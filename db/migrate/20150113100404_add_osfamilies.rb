# This migration creates all the necessary schema models to ensure flavor and appliance type
# differentiation into OS families (typically Linux and Windows). This is necessary to facilitate
# proper billing where the price of a flavor depends on the installed OS.

class AddOsfamilies < ActiveRecord::Migration[4.2]
  def up
    create_table :atmosphere_os_families do |t|
      t.string :name, null:false, default: "Windows"
    end

    create_table :atmosphere_flavor_os_families do |t|

      t.integer :hourly_cost

      t.belongs_to :virtual_machine_flavor
      t.belongs_to :os_family
    end

    add_reference :atmosphere_appliance_types, :os_family, index: true

    # Spawn two records and rewrite existing ATypes to bind to a specific os_family
    os_windows = Atmosphere::OSFamily.find_or_create_by(name: 'Windows')
    os_linux = Atmosphere::OSFamily.find_or_create_by(name: 'Linux')

    # for some reason we need to force ApplianceType model class
    # without it rake migrate:redo failed
    Atmosphere::ApplianceType.reset_column_information

    # Rewrite all existing ATs to use the 'windows' OS (correct later as necessary)

    Atmosphere::ApplianceType.find_each do |atype|
      atype.os_family = os_windows
      atype.save
    end

    # Assign an os_family to each existing flavor and rewrite cost
    Atmosphere::VirtualMachineFlavor.find_each do |flavor|
      vmf_osf = Atmosphere::FlavorOSFamily.create(virtual_machine_flavor: flavor,
        os_family: Atmosphere::OSFamily.first,
        hourly_cost: flavor.read_attribute('hourly_cost'))
    end

    remove_column :atmosphere_virtual_machine_flavors, :hourly_cost

  end

  def down
    add_column :atmosphere_virtual_machine_flavors, :hourly_cost, :integer, default: 0

    Atmosphere::VirtualMachineFlavor.find_each do |f|
      f_osfamily = f.flavor_os_families.first
      unless f_osfamily.blank?
        f.hourly_cost = f_osfamily.hourly_cost
        f.save
      end
    end

    remove_column :atmosphere_appliance_types, :os_family_id

    drop_table :atmosphere_flavor_os_families
    drop_table :atmosphere_os_families
  end
end
