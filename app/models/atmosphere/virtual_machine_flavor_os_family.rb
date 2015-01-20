# This class provide a m:n link between VM flavors and OS families.
# It also stores the hourly cost for each flavor for the specific OS family.
module Atmosphere
  class VirtualMachineFlavorOSFamily < ActiveRecord::Base
    belongs_to :virtual_machine_flavor,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    belongs_to :os_family,
      class_name: 'Atmosphere::OSFamily'

    #validates :hourly_cost,
    #  numericality: { greater_than_or_equal_to: 0 }

  end
end
