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
  def self.at_pdp(user)
    (at_pdp_class || Atmosphere::DefaultPdp).new(user)
  end

  mattr_reader :config_param
  @@config_param = Struct.new(:regexp, :range).new(/\#{\w*}/, 2..-2)

  mattr_reader :url_monitoring
  @@url_monitoring = Struct.new(:unavail_statuses, :pending, :ok, :lost)
    .new([502], 10, 120, 15)

  mattr_reader :optimizer
  @@optimizer = Struct.new(:max_appl_no).new(5)

  mattr_reader :monitoring
  @@monitoring = Struct.new(:query_interval).new(5)

  mattr_accessor :childhood_age #seconds
  @@childhood_age = 2

  mattr_accessor :cloud_object_protection_time #seconds
  @@cloud_object_protection_time = 300

  mattr_accessor :cloud_client_cache_time #hours
  @@cloud_client_cache_time = 8

  mattr_accessor :vmt_at_relation_update_period #hours
  @@vmt_at_relation_update_period = 2

  mattr_accessor :monitoring_client
  def self.monitoring_client
    @@monitoring_client || Atmosphere::Monitoring::NullClient.new
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
    cache_expiration_time = cloud_client_cache_time.hours

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

  def self.metrics_store
    influxdb_client || Atmosphere::Monitoring::NullMetricsStore.new
  end

  def self.clear_cache!
    @clients_cache = nil
  end

  private

  def self.clients_cache
    @clients_cache ||= {}
  end

  def self.client_cache_entry(key)
    clients_cache[key] || Atmosphere::NullCacheEntry.new
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