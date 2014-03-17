class HttpMappingMonitoringWorker

  include Sidekiq::Worker

  @@reg_checks = {}

  def initialize(check = UrlAvailabilityCheck.new)
    @check = check
  end

  def perform(mapping_id, serial_no = nil)

    mapping = HttpMapping.find_by id: mapping_id

    # By setting status to HttpMappingStatus::NOT_MONITORED one can disable monitoring
    if (mapping.nil? || mapping.monitoring_status != HttpMappingStatus::NOT_MONITORED)
      logger.info("Unregistering monitoring for http mapping")
      unregister(mapping_id)
      return
    end

    if (serial_no.nil?)
      serial_no = register(mapping_id)
    end

    if (allowed_for_monitoring(mapping, serial_no))
      perform_check(mapping)
      schedule_next(mapping, serial_no)
    else
      logger.info("Worker not allowed to perform check. Monitoring already scheduled.")
    end

  end

  def unregister(mapping_id)
    @@reg_checks[mapping_id] = nil
  end

  def register(mapping_id)
    uuid = SecureRandom.uuid
    @@reg_checks[mapping_id] = uuid
    uuid
  end

  def allowed_for_monitoring(mapping, serial_no)
    (@@reg_checks[mapping.id] == serial_no)
  end

  def perform_check(mapping)
    logger.info("Performing check for #{mapping.id}")
    if @check.is_available(mapping.url)
      mapping.monitoring_status = HttpMappingStatus::OK
    else
      old_status = mapping.monitoring_status
      if old_status == HttpMappingStatus::OK
        mapping.monitoring_status = HttpMappingStatus::LOST
      else
        mapping.monitoring_status = HttpMappingStatus::PENDING
      end
    end
    mapping.save
  end

  def schedule_next(mapping, serial_no)
    interval = 2.seconds
    if (mapping.monitoring_status == HttpMappingStatus::OK) || (mapping.monitoring_status == HttpMappingStatus::LOST)
      interval = 10.seconds
    end
    HttpMappingMonitoringWorker.perform_in(interval, mapping.id, serial_no)
  end

end