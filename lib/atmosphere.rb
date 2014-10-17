require 'haml-rails'
require 'devise'
require 'atmosphere/engine'
require 'atmosphere/cache_entry'

module Atmosphere

  # Default way to setup Atmosphere.
  def self.setup
      yield self
    end

  # If user credentials should be delegated into spawned VM than delegated
  # auth value can be used. It will automatically inject into every initial
  # configuration instance parameter with delegation_key value as a key
  # and result of delegate_auth method implemented in
  # /app/controllers/concerns/api/*/appliances_controller_ext.rb.
  mattr_accessor :delegation_initconf_key

  # List of additional resources which should be presented while login
  # as admin user. List should be namespaced with router name. For main
  # rails application use following format:
  #
  #  {
  #    main_app: { AdditionalResourceViewsToShow }
  #  }
  mattr_accessor :admin_entites_ext
  @@admin_entites_ext = {}

  def self.admin_entities
    entities = {
      atmosphere: [
        Atmosphere::ApplianceType,
        Atmosphere::ApplianceSet,
        Atmosphere::ComputeSite,
        Atmosphere::VirtualMachine,
        Atmosphere::VirtualMachineTemplate,
        Atmosphere::UserKey
      ]
    }

    entities.merge(admin_entites_ext)
  end

  # sidekiq redis url.
  mattr_accessor :sidekiq
  @@sidekiq = Struct.new(:url, :namespace)
    .new('redis://localhost:6379', 'atmosphere')

  # PDP class for defining which Appliance Types user is able to start in
  # development, production mode and which Appliance Types user is able to
  # manage.
  mattr_accessor :at_pdp_class

  mattr_reader :config_param
  @@config_param = Struct.new(:regexp, :range).new(/\#{\w*}/, 2..-2)

  def self.at_pdp(user)
    (at_pdp_class || Atmosphere::DefaultPdp).new(user)
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

    clients_cache[site_id] =
      Atmosphere::CacheEntry.new(cloud_client, cache_expiration_time)
  end

  def self.unregister_cloud_client(site_id)
    clients_cache.delete(site_id)
  end

  def self.get_cloud_client(site_id)
    cached = client_cache_entry(site_id)

    cached.valid? ? cached.value : nil
  end

  def self.monitoring_client
    zabbix_client || Atmosphere::Monitoring::NullClient.new
  end

  def self.metrics_store
    influxdb_client || Atmosphere::Monitoring::NullMetricsStore.new
  end

  def self.clear_cache!
    @clients_cache = nil
  end

  private

  def self.zabbix_client
    if config['zabbix']
      clients_cache['zabbix'] ||= Atmosphere::Monitoring::ZabbixClient.new
    end
  end

  def self.clients_cache
    @clients_cache ||= {}
  end

  def self.client_cache_entry(key, null_client_class = Atmosphere::NullCacheEntry)
    clients_cache[key] || null_client_class.new
  end

  def self.influxdb_client
    cached_client = self.client_cache_entry('influxdb')
    if config['influxdb'] && !cached_client.valid?
      client = Atmosphere::Monitoring::InfluxdbMetricsStore.new(config['influxdb'])
      cached_client = Atmosphere::CacheEntry.new(client, 60.minutes)
      clients_cache['influxdb'] = cached_client
    end
    cached_client.value
  end

  def self.config
    Air.config
  end
end