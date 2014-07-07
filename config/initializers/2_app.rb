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
    self.zabbix_client || Monitoring::NullClient.new
  end

  def self.metrics_store
    self.influxdb_client || Monitoring::NullMetricsStore.new
  end

  private

  def self.zabbix_client
    if config['zabbix']
      self.clients_cache['zabbix'] ||= Monitoring::ZabbixClient.new
    end
  end

  def self.clients_cache
    @clients_cache ||= {}
  end

  def self.client_cache_entry(key, null_client_class = NullCacheEntry)
    self.clients_cache[key] || null_client_class.new
  end

  def self.influxdb_client
    cached_client = self.client_cache_entry('influxdb')
    if config['influxdb'] && !cached_client.valid?
      client = Monitoring::InfluxdbMetricsStore.new(config['influxdb'])
      cached_client = CacheEntry.new(client, 60.minutes)
      self.clients_cache['influxdb'] = cached_client
    end
    cached_client.value
  end
end