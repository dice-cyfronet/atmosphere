module Atmosphere
  #
  # Save appliance in DB and trigger appliance optimization.
  #
  class CreateApplianceService
    def initialize(appliance)
      @appliance = appliance
    end

    def execute
      appliance.save.tap do |success|
        if success
          Atmosphere::Cloud::OptimizeApplianceWorker.perform_async(appliance.id)
        end
      end
    end

    private

    attr_reader :appliance
  end
end
