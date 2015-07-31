# This class provide a m:n link between VM flavors and OS families.
# It also stores the hourly cost for each flavor for the specific OS family.
module Atmosphere
  class FlavorOSFamily < ActiveRecord::Base
    belongs_to :virtual_machine_flavor,
               inverse_of: :flavor_os_families,
               class_name: 'Atmosphere::VirtualMachineFlavor'

    belongs_to :os_family,
               class_name: 'Atmosphere::OSFamily'

    before_destroy :cant_destroy_if_vm_are_running

    private

    def cant_destroy_if_vm_are_running
      vms = virtual_machine_flavor.virtual_machines.manageable.select do |vm|
        vm.try(:source_template).
        try(:appliance_type).
        try(:os_family) == os_family
      end
      if vms.present?
        errors.add :base, I18n.t('flavor_os_family.running_vms')
        false
      end
    end
  end
end
