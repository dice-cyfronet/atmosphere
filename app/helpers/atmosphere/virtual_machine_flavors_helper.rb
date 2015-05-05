module Atmosphere
  module VirtualMachineFlavorsHelper
    def each_os_family(&block)
      capture do
        Atmosphere::OSFamily.find_each do |os_family|
          yield os_family
        end
      end
    end
  end
end
