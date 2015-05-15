module Atmosphere
  class DestroyAppliance
    def initialize(appliance, options = {})
      @appliance = appliance
      @billing_service = options.fetch(:billing_service, BillingService)
      @vm_cleaner = options.fetch(:vm_cleaner, Cloud::DestroyUnusedVms).new
    end

    def execute
      @billing_service.bill_appliance(@appliance, Time.now.utc,
                                    I18n.t('billing.final'), false)

      @appliance.destroy.tap do |success|
        @vm_cleaner.execute if success
      end
    end
  end
end
