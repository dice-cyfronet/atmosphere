class EndpointStatusCheckWorker

  include Sidekiq::Worker

  def initialize(check = UrlAvailabilityCheck.new)
    @check = check
  end

  def perform(mapping_id)
    mapping = HttpMapping.find_by id: mapping_id
    if @check.is_available(mapping.url)
      mapping.monitoring_status = :ok
    elsif mapping.monitoring_status.ok?
        mapping.monitoring_status = :lost
    end
    mapping.save
  end

end