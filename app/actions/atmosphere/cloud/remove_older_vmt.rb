# Remove all virtual machine templates assigned to the same
# appliance type as given template with version smaller than
# given template has.
module Atmosphere
  module Cloud
    class RemoveOlderVmt
      def initialize(vmt)
        @vmt = vmt
      end

      def execute
        older_at_vmts.each(&:destroy)
      end

      private

      def older_at_vmts
        Atmosphere::VirtualMachineTemplate.where(at_vmts.and(older))
      end

      def at_vmts
        vmt_table[:appliance_type_id].eq(@vmt.appliance_type_id)
      end

      def older
        vmt_table[:version].lt(@vmt.version)
      end

      def vmt_table
        Atmosphere::VirtualMachineTemplate.arel_table
      end
    end
  end
end
