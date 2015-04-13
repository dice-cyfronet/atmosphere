module Atmosphere
  class ActCopier
    def initialize(appliance_type)
      @appliance_type = appliance_type
    end

    def execute
      create_copy if @appliance_type
    end

    private

    def create_copy
      @appliance_type.appliance_configuration_templates.map do |act|
        copy = act.dup
        copy.appliance_type = nil
        copy
      end
    end
  end
end
