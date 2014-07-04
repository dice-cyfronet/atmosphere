require 'cache_entry'

module Air
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end

  ## LOGGERS ##

  def self.action_logger
    @action_logger ||= Logger.new(Rails.root.join('log', 'user_actions.log'))
  end

  def self.monitoring_logger
    @monitoring_logger ||= Logger.new(Rails.root.join('log', 'monitoring.log'))
  end

  def self.optimizer_logger
    @optimizer_logger ||= Logger.new(Rails.root.join('log', 'optimizer.log'))
  end

  ## CLIENTS ##

  def self.register_cloud_client(site_id, cloud_client)
    cache_expiration_time = config.cloud_client_cache_time.hours

    self.clients_cache[site_id] =
      CacheEntry.new(cloud_client, cache_expiration_time)
  end

  def self.unregister_cloud_client(site_id)
    self.clients_cache.delete(site_id)
  end

  def self.get_cloud_client(site_id)
    cached = self.client_cache_entry(site_id)

    cached.valid? ? cached.value : nil
  end

  def self.monitoring_client
    if config['zabbix']
      if @monitoring_clients['zabbix']
        @monitoring_clients['zabbix']
      else
        client = Monitoring::ZabbixClient.new
        @monitoring_clients['zabbix'] = client
        client
      end
    else
      @monitoring_clients['null']
    end
  end

  def self.metrics_store
    if config['influxdb']
      if @metrics_store_clients['influxdb'] && @metrics_store_clients['influxdb']['client'] && (Time.now - @metrics_store_clients['influxdb']['timestamp']) < 60.minutes
        @metrics_store_clients['influxdb']['client']
      else
        client = Monitoring::InfluxdbMetricsStore.new(config['influxdb'])
        @metrics_store_clients['influxdb'] = {}
        @metrics_store_clients['influxdb']['client'] = client
        @metrics_store_clients['influxdb']['timestamp'] = Time.now
        client
      end
    else
      @metrics_store_clients['null']
    end
  end

  private

  @monitoring_clients = {'null' => Monitoring::NullClient.new}
  @metrics_store_clients = {'null' => Monitoring::NullMetricsStore.new}

  def self.clients_cache
    @clients_cache ||= {}
  end

  def self.client_cache_entry(key, null_client_class = NullCacheEntry)
    self.clients_cache[key] || null_client_class.new
  end
end