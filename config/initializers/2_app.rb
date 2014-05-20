module Air
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end

  @@cloud_clients = {}
  @@monitoring_clients = {'null' => Monitoring::NullClient.new}
  @@metrics_store_clients = {'null' => Monitoring::NullMetricsStore.new}

  def self.register_cloud_client(site_id, cloud_client)
    @@cloud_clients[site_id] = {timestamp: Time.now, client: cloud_client}
  end

  def self.unregister_cloud_client(site_id)
    @@cloud_clients.delete(site_id)
  end

  def self.get_cloud_client(site_id)
    (@@cloud_clients[site_id] && (Time.now - @@cloud_clients[site_id][:timestamp]) < 23.hours) ? @@cloud_clients[site_id][:client] : nil
  end

  def self.action_logger
    @@action_logger ||= Logger.new(Rails.root.join('log', 'user_actions.log'))
  end

  def self.monitoring_logger
    @@monitoring_logger ||= Logger.new(Rails.root.join('log', 'monitoring.log'))
  end

  def self.monitoring_client
    if config['zabbix']
      if @@monitoring_clients['zabbix']
        @@monitoring_clients['zabbix']
      else
        client = Monitoring::ZabbixClient.new
        @@monitoring_clients['zabbix'] = client
        client
      end
    else
      @@monitoring_clients['null']
    end
  end

  def self.metrics_store
    if config['influxdb']
      if @@metrics_store_clients['influxdb'] && @@metrics_store_clients['influxdb']['client'] && (Time.now - @@metrics_store_clients['influxdb']['timestamp']) < 60.minutes
        @@metrics_store_clients['influxdb']['client']
      else
        client = Monitoring::InfluxdbMetricsStore.new(config['influxdb'])
        @@metrics_store_clients['influxdb']['client'] = client
        @@metrics_store_clients['influxdb']['timestamp'] = Time.now
        client
      end
    else
      @@metrics_store_clients['null']
    end
  end

end