# Save first appliance VM as target_at VMT
module Atmosphere
  module Cloud
    class Save
      def initialize(appliance, target_at)
        @appliance = appliance
        @target_at = target_at
      end

      def execute
        vmt = VirtualMachineTemplate.create_from_vm(vm)
        @target_at.virtual_machine_templates << vmt
      end

      private

      def vm
        @appliance.virtual_machines.first
      end
    end
  end
end
