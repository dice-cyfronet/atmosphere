class BillingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :billing
  sidekiq_options :retry => false

  def perform
    begin
      Rails.logger.info "Performing mass billing operation for all appliances."
      BillingService::bill_all_appliances
      Rails.logger.info "Applying funding policy to all virtual machines."
      BillingService::apply_funding_policy
    end
  end
end