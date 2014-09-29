module Atmosphere
  class ActCopier
    def self.copy(at)
      at.appliance_configuration_templates.collect do |act|
        copy = act.dup
        copy.appliance_type = nil
        copy
      end if at
    end
  end
end