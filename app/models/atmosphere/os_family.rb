module Atmosphere
  class OSFamily < ActiveRecord::Base

    has_many :appliance_types,
      class_name: 'Atmosphere::ApplianceType'

    has_many :virtual_machine_flavors,
      through: :virtual_machine_flavor_os_families,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    has_many :virtual_machine_flavor_os_families,
      class_name: 'Atmosphere::VirtualMachineFlavorOSFamily'

    validates :os_family_name,
      presence: true

  end
end
