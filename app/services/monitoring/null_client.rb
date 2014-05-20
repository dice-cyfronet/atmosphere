class Monitoring::NullClient

  def register_in_monitoring; nil end
  
  def unregister_from_monitoring; end

  def current_load_metrics; nil end

  def host_metrics(monitoring_id); nil end

end