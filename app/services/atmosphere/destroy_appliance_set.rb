module Atmosphere
  class DestroyApplianceSet
    def initialize(appliance_set)
      @appliance_set = appliance_set
    end

    def execute
      @appliance_set.appliances.each do |appliance|
        unless DestroyAppliance.new(appliance).execute
          @appliance_set.errors.
            add(I18n.t('appliance_sets.cannot_remove_appliance',
                       appliance: appliance))
        end
      end

      @appliance_set.destroy
    end
  end
end
