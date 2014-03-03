class FlavorWorker
  include Sidekiq::Worker

  sidekiq_options queue: :flavors
  sidekiq_options :retry => false

  def perform
    begin
      Rails.logger.info "Updating flavor info for all cloud sites."
      FlavorManager::scan_all_sites
    end
  end
end