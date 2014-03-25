class HttpMappingMonitoringWorker

  include Sidekiq::Worker

  def initialize(status_check = BasicStatusCheck.new)
     @status_check = status_check
  end

  def perform(status)
    mappings = HttpMapping.where(:monitoring_status => status)
    mappings.each do |mapping|
      @status_check.submit(mapping.id)
    end
  end

  class BasicStatusCheck
    def submit(mapping_id)
      EndpointStatusCheckWorker.perform_async(mapping_id)
    end
  end

end