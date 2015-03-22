module Atmosphere
  class OSFamily < ActiveRecord::Base

    has_many :appliance_types,
      class_name: 'Atmosphere::ApplianceType'

    has_many :dev_mode_property_sets,
      class_name: 'Atmosphere::DevModePropertySet'

    has_many :virtual_machine_flavors,
      through: :flavor_os_families,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    has_many :flavor_os_families,
      class_name: 'Atmosphere::FlavorOSFamily'

    validates :name,
      presence: true

  end
end
