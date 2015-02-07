# This class provide a m:n link between VM flavors and OS families.
# It also stores the hourly cost for each flavor for the specific OS family.
module Atmosphere
  class VirtualMachineFlavorOSFamily < ActiveRecord::Base
    belongs_to :virtual_machine_flavor,
      inverse_of: :virtual_machine_flavor_os_families,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    belongs_to :os_family,
      class_name: 'Atmosphere::OSFamily'

  end
end
