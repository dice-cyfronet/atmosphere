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
        Atmosphere::Cloud::SatisfyAppliance.new(appliance).execute if success
      end
    end

    private

    attr_reader :appliance
  end
end
