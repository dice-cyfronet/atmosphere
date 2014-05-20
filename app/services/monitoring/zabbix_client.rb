require 'zabbix'

class Monitoring::ZabbixClient

  def register_host(uuid, ip)
    Zabbix.register_host(uuid, ip)
  end

  def unregister_host(monitoring_id)
    Zabbix.unregister_host(monitoring_id)
  end

  def host_metrics(monitoring_id)
    Zabbix.host_metrics(monitoring_id)
  end

end