class Monitoring::NullClient

  def register_host(uuid, ip); nil end
  
  def unregister_host(monitoring_id); end

  def host_metrics(monitoring_id); nil end

end