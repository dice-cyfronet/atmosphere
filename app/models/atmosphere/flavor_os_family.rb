# This class provide a m:n link between VM flavors and OS families.
# It also stores the hourly cost for each flavor for the specific OS family.
module Atmosphere
  class FlavorOSFamily < ActiveRecord::Base
    belongs_to :virtual_machine_flavor,
      inverse_of: :flavor_os_families,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    belongs_to :os_family,
      class_name: 'Atmosphere::OSFamily'

    validates :virtual_machine_flavor,
              presence: true

    validates :os_family,
              presence: true
  end
end
